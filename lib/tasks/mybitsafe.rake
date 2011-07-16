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
  
  task :pay_faucet do
    Deal.pay_faucet
  end

  task :pay_out do
    payment_address = ENV['addr']
    payment_amount = ENV['amount']

    raise "USAGE: rake environment mybitsafe:pay_self amount=10 addr=124345342532453425" if payment_address.nil? or payment_amount.nil?
    
    RakeLineItem.pay_out payment_amount, payment_address
  end

  task :stats do
    total_users = User.find(:all).length
    new_users = User.find(:all).select { |u| u.created_at > (Time.now - 1.days) }.length
    unconfirmed = User.find(:all).select { |u| u.confirmed_at.nil? }.length

    puts "USERS: #{total_users} (#{new_users} last 24 hours) (#{unconfirmed} unconfirmed)"

    total_deals = Deal.find(:all).length
    new_deals = Deal.find(:all).select { |u| u.created_at > (Time.now - 1.days) }.length

    puts "DEALS: #{total_deals} (#{new_deals} last 24 hours)"
  end
end
