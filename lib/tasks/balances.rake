namespace :mybitsafe do
  task :balance do
    puts"Acct\tDEBIT\tCREDIT\tBALANCE"
    deal_debit, deal_credit, deal_balance = DealLineItem.get_balances
    puts "DEAL\t#{deal_debit}\t#{deal_credit}\t#{deal_balance}"
    reserve_debit, reserve_credit, reserve_balance = ReserveLineItem.get_balances
    puts "RESERVE\t#{reserve_debit}\t#{reserve_credit}\t#{reserve_balance}"
    rake_debit, rake_credit, rake_balance = RakeLineItem.get_balances
    puts "RAKE\t#{rake_debit}\t#{rake_credit}\t#{rake_balance}"
  end
  
end
