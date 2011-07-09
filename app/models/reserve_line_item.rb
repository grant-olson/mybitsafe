class ReserveLineItem < ActiveRecord::Base
  def self.log4r
    Log4r::Logger['reserve_line_items']
  end
  
  def self.get_balances
    debit = 0.0
    credit = 0.0
    balance = 0.0

    ReserveLineItem.find(:all).each do |li|
      debit += li.debit
      credit += li.credit
      balance += (li.credit - li.debit)
    end

    [debit,credit,balance]
  end

  def self.book_tx_fees
    Bitcoind.deal_transactions(Bitcoind::RESERVE_ACCOUNT).each do |tx|
      next if tx['category'] != 'send'
      next if tx['fee'] >= 0.0

      fee = -tx['fee']
      txid = tx['txid']

      log4r.info "Transaction #{txid} had fee of #{fee}"

      if ReserveLineItem.find_by_note(txid)
        log4r.info "Already booked"
      else
        log4r.info "booking new tx fee"
        ActiveRecord::Base.transaction do
          ReserveLineItem.new(:debit => fee, :credit => 0, :note => txid).save!
          RakeLineItem.new(:debit => fee, :credit => 0, :note => "Fee for tx #{txid}").save!
        end
      end
    end
    nil
  end
  
end
