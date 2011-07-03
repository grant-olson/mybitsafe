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
      elsif
        tx['category'] == 'send'

        fee = tx['fee']
        fee = 0 if fee.nil?
        fee = - fee

        if tx['address'] == Bitcoind::RAKE_ADDRESS
          log4r.info "Rake Transaction..."
          deal_line_items.create :tx_id => tx['txid'], :debit => -tx['amount'], :credit => 0, :fee => fee, :tx_type => "RAKE"
        elsif tx['address'] == release_address
          log4r.info "Release Transaction..."
          deal_line_items.create :tx_id => tx['txid'], :debit => tx['amount'], :credit => 0, :fee => fee, :tx_type => "RELEASE"
        else
          log4r.error "SUSPICIOUS TRANSACTION.  NOT RAKE OR RELEASE.  #{tx['address']}"
        end
      else
        raise ArgumentError, "Unknown category type #{tx['category']}..."
      end
    end
  end
  
end
