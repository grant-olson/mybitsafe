class Deal < ActiveRecord::Base
  has_many :deal_line_items

  def log4r
    Log4r::Logger['deals']
  end
  
  def move_deposits_to_reserve
    log4r.info "Moving new deposits to reserve..."
    transactions = Bitcoind.deal_transactions self.uuid

    receive = transactions.select { |tx| tx['category'] == 'receive' }
    send = transactions.select { |tx| tx['category'] == 'send'}
    move = transactions.select { |tx| tx['categiry'] == 'move' }
    
    raise "Crazy category" if transactions.length != (receive.length + send.length + move.length)
    raise "How'd we get a send" if send.length > 0

    confirmed_receive = receive.select { |tx| tx['confirmations'] >= Bitcoind::MIN_CONFIRMS }
    log4r.info "Received #{receive.length} transactions, #{confirmed_receive.length} confirmed..."

    move_ids = {}
    move.each do |mv|
      move_ids[mv['comment']] == move
    end

    confirmed_receive.each do |tx|
      if move.has_key? tx['txid']
        log "Already moved #{tx['txid']}, skipping..."
      else
        log "Didn't move #{tx['txid']} yet, moving..."
        Bitcoind.deal_move_deposit uuid, tx['amount'], tx['txid']
        deal_line_items.create :tx_id => tx['txid'], :credit => tx['amount'], :debit => 0, :tx_type => "DEPOSIT"
        ReserveLineItem.new :credit => tx['amount'], :debit => 0, :note => tx['txid']
      end
    end
    
  end

  def take_rake
    log4r.info "Taking rake..."

    total_deposits = line_item_deposits.to_i

    if total_deposits == 0
      log4r.info "No deposits yet... No rake"
      return
    end
    
    hundreds = (total_deposits / 100) + 1
    expected_rake = hundreds.to_f * 0.025
    log4r.info "Total Deposits #{total_deposits}, expected rake #{expected_rake}..."
    
    total_rake = line_item_rakes
    log4r.info "Current rake #{total_rake}"

    remaining_rake = expected_rake - total_rake

    if remaining_rake > 0
      log4r.info "Taking rake"
      deal_line_items.create :debit => remaining_rake, :credit => 0, :tx_type => "RAKE"
      RakeLineItem.new :debit => 0, :credit => remaining_rake, :note => "Rake from #{deal.uuid}"
    else
      log4r.info "Rake good.  Skipping"
    end
    
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
      li.debit
    end
    
    return 0.0 if amounts.nil? or amounts.empty?
    
    return amounts.reduce { |a,b| a + b}
  end
  
  def line_item_balance
    amounts = deal_line_items.map do |li|
      li.credit - li.debit
    end
    
    return 0.0 if amounts.nil? or amounts.empty?
    
    return amounts.reduce { |a,b| a + b}
  end
  
end
