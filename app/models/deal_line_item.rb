class DealLineItem < ActiveRecord::Base
  belongs_to :deal

  def self.get_balances
    debit = 0.0
    credit = 0.0
    balance = 0.0

    DealLineItem.find(:all).each do |li|
      debit += li.debit
      credit += li.credit
      balance += (li.credit - li.debit)
    end

    [debit,credit,balance]
  end
  

end
