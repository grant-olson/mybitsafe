class Deal < ActiveRecord::Base
  has_many :deal_line_items

  EXPIRES_IN = 1 

  class ReleaseFundsError < StandardError;end

  def log4r
    Log4r::Logger['deals']
  end
  
  def move_deposits_to_reserve
    log4r.info "Moving new deposits to reserve..."
    transactions = Bitcoind.deal_transactions self.uuid

    receive = transactions.select { |tx| tx['category'] == 'receive' }
    send = transactions.select { |tx| tx['category'] == 'send'}
    move = transactions.select { |tx| tx['category'] == 'move' }
    
    raise "Crazy category #{transactions.length} #{receive.length} #{move.length} #{send.inspect}" if transactions.length != (receive.length + send.length + move.length)
    raise "How'd we get a send" if send.length > 0

    confirmed_receive = receive.select { |tx| tx['confirmations'] >= Bitcoind::MIN_CONFIRMS }
    log4r.info "Received #{receive.length} transactions, #{confirmed_receive.length} confirmed..."

    move_ids = {}
    move.each do |mv|
      move_ids[mv['comment']] = move
    end

 #   raise move_ids.keys.inspect + " " + confirmed_receive.first.inspect
    confirmed_receive.each do |tx|
      if move_ids.has_key? tx['txid']
        log4r.info "Already moved #{tx['txid']}, skipping..."
      else
        log4r.info "Didn't move #{tx['txid']} yet, moving..."
        Bitcoind.deal_move_deposit uuid, tx['amount'], tx['txid']
        deal_line_items.create :tx_id => tx['txid'], :credit => tx['amount'], :debit => 0, :tx_type => "DEPOSIT"
        ReserveLineItem.new(:credit => tx['amount'], :debit => 0, :note => tx['txid']).save!
      end
    end
    
  end

  def take_rake
    log4r.info "Taking rake..."

    if line_item_deposits <= 0
      log4r.info "No deposits yet... No rake"
      return
    end
    
    expected_rake = 0.0
    amount = line_item_deposits
    while amount > 0
      expected_rake += Const::RAKE_FEE
      amount -= (100 + Const::RAKE_FEE)
    end
    
    log4r.info "Total Deposits #{line_item_deposits}, expected rake #{expected_rake}..."
    
    total_rake = line_item_rakes
    log4r.info "Current rake #{total_rake}"

    remaining_rake = expected_rake - total_rake

    if remaining_rake > 0
      log4r.info "Taking rake #{remaining_rake}"
      deal_line_items.create :debit => remaining_rake, :credit => 0, :tx_type => "RAKE"
      RakeLineItem.new(:debit => 0, :credit => remaining_rake, :note => "Rake from #{uuid}").save!
    else
      log4r.info "Rake good.  Skipping"
    end
    
  end

  def release amount
    amount = amount.to_f
    
    if amount < 0.1
      raise ReleaseFundsError, "Amount must be greater than 0.01 BTC.  You tried to send #{amount}"
    end

    if amount > line_item_balance
      raise ReleaseFundsError, "#{amount} is greater than available funds."
    end
    
    log4r.info ("Releasing #{amount}  via bitcoind...")
    Bitcoind.deal_pay uuid, release_address, amount
    log4r.info ("Adding debit to deal line items...")
    deal_line_items.create :debit => amount, :credit => 0, :tx_type => "RELEASE"
    log4r.info ("Adding debit to reserve account...")
    ReserveLineItem.new(:debit => amount, :credit => 0, :note => "Release for #{uuid}").save!
  end

  def line_item_rakes
    rake_line_items = deal_line_items.select { |li| li.tx_type == "RAKE" }

    amounts = rake_line_items.map do |li|
      li.debit
    end
    
    return 0.0 if amounts.nil? or amounts.empty?
    
    return amounts.reduce { |a,b| a + b}
  end
  
  def line_item_deposits
    amounts = deal_line_items.map do |li|
      li.credit
    end
    
    return 0.0 if amounts.nil? or amounts.empty?
    
    return amounts.reduce { |a,b| a + b}
  end
  
  def line_item_balance
    amounts = deal_line_items.map do |li|
      li.credit - li.debit
    end
    
    return 0.0 if amounts.nil? || amounts.empty?
    
    return amounts.reduce { |a,b| a + b}
  end

  def expires_in
    (expires_on - Time.now).to_f / (60 * 60 * 24).to_f
  end

  def expires_on
    created_at + EXPIRES_IN.days
  end
  
  def expired?
    expires_on < Time.now()
  end
  
end
