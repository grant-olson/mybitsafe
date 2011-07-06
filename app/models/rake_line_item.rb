class RakeLineItem < ActiveRecord::Base
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
end
