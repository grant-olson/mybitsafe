class Deal < ActiveRecord::Base
  has_many :deal_line_items

  def log4r
    Log4r::Logger['deals']
  end
  
  def sync_books
    log4r.info "Seeing if we need to get rake..."
    Bitcoind.deal_rake self.uuid

    log4r.info "Looking up transactions #{self.uuid}...."
    transactions = Bitcoind.deal_transactions self.uuid

    transactions.each do |tx|
      if deal_line_items.find_by_tx_id(tx['txid'])
        log4r.info("Skipping... Transaction #{tx['tx_id']} is already recorded...")
        next
      end

      if tx['category'] == 'receive'
        log4r.info "Deposit..."
        deal_line_items.create :tx_id => tx['txid'], :credit => tx['amount'], :debit => 0, :fee => 0, :tx_type => "DEPOSIT"
      elsif tx['category'] == 'move'
        log4r.info "Rake Transaction..."
        deal_line_items.create :tx_id => tx['txid'], :debit => -tx['amount'], :credit => 0, :fee => 0, :tx_type => "RAKE"

      elsif tx['category'] == 'send'

        fee = tx['fee']
        fee = 0 if fee.nil?
        fee = - fee

        if tx['address'] == release_address
          log4r.info "Release Transaction..."
          deal_line_items.create :tx_id => tx['txid'], :debit => tx['amount'], :credit => 0, :fee => fee, :tx_type => "RELEASE"
        else
          log4r.error "SUSPICIOUS TRANSACTION.  NOT THE RELEASE ADDRESS.  #{tx['address']}"
        end
      else
        raise ArgumentError, "Unknown category type #{tx['category']}..."
      end
    end
  rescue Bitcoind::BitcoindDown => ex
    nil # Fail gracefully.
  end

  def line_item_balance
    amounts = deal_line_items.map do |li|
      fee = li.fee
      fee = 0 if li.fee.nil?

      li.credit - li.debit - fee
    end
    
    return 0.0 if amounts.nil? or amounts.empty?
    
    return amounts.reduce { |a,b| a + b}
  end
  
  def books_balance?
    lib = line_item_balance
    db = Bitcoind.deal_balance uuid

    log4r.info "Comparing line_item_balance #{line_item_balance} to bitcoin_balance #{db}"
    res = (lib == db)
    log4r.info (res == true ? "they are equal" : "they are not equal")
    res
  end
  
end
