class RakeLineItem < ActiveRecord::Base
  def self.log4r
    Log4r::Logger['reserve_line_items']
  end
  
  def self.get_balances
    debit = 0.0
    credit = 0.0
    balance = 0.0

    RakeLineItem.find(:all).each do |li|
      debit += li.debit
      credit += li.credit
      balance += (li.credit - li.debit)
    end

    [debit,credit,balance]
  end

  def self.pay_out amount, address
    log4r.info "Preparing to release #{amount} to #{address}"
    amount = amount.to_f

    debit, credit, balance = get_balances
    raise "NOT ENOUGH MONEY" if balance < amount

    raise "TOO SMALL AMOUNT" if amount < 0.01

    Bitcoind.deal_pay Bitcoind::RESERVE_ACCOUNT, address,  amount
    ActiveRecord::Base.transaction do
      ReserveLineItem.new(:debit => amount, :credit => 0, :note => "Rake Release to #{address}").save!
      RakeLineItem.new(:debit => amount, :credit => 0, :note => "Rake Release to #{address}").save!
    end

    log4r.info "Funds released"
  end
  
end
