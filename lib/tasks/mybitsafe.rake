namespace :mybitsafe do
  task :balance do
    puts"Account\tDEBIT\tCREDIT\tBALANCE"
    puts "DEAL\t%.4f\t%.4f\t%.4f" % DealLineItem.get_balances
    puts "RESERVE\t%.4f\t%.4f\t%.4f" % ReserveLineItem.get_balances
    puts "RAKE\t%.4f\t%.4f\t%.4f" % RakeLineItem.get_balances
    puts
    puts "WALLET\t\t\t%.4f" % Bitcoind.wallet_balance
  end

  task :book_tx_fees do
    puts "Booking new tx fees..."
    ReserveLineItem.book_tx_fees
  end
  
  task :pay_fountain do
    Deal.pay_fountain
  end

  task :pay_out do
    payment_address = ENV['addr']
    payment_amount = ENV['amount']

    raise "USAGE: rake environment mybitsafe:pay_self amount=10 addr=124345342532453425" if payment_address.nil? or payment_amount.nil?
    
    RakeLineItem.pay_out payment_amount, payment_address
  end
end
