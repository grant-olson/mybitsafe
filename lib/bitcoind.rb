module Bitcoind

  CONN = ServiceProxy.new("http://grant:test@127.0.0.1:8332")
  RAKE_RATE = 0.025
  RAKE_ADDRESS = "muHHR6JNx2mJr1Rwa8n8K324u8YiHdAzdd"
  MIN_CONFIRMS = 1

  def self.log4r
    Log4r::Logger['bitcoind']
  end
  
  def self.new_deal user, destination_address
    log4r.info("Validating address #{destination_address}")
    CONN.validateaddress.call destination_address
    deal_name = UUIDTools::UUID.random_create.to_s
    log4r.info("Creating new deal #{deal_name} for #{user} to #{destination_address}")
    address = CONN.getnewaddress.call deal_name
    log4r.info("Got address #{address}")
    [deal_name, address]
  end
  
  def self.deal_balance deal_name, confirmed = true
    min_confs = MIN_CONFIRMS
    min_confs = 0 if confirmed == false

    log4r.info("Getting #{confirmed ? "confirmed" : "unconfirmed"} balance for account #{deal_name}...")
    res = CONN.getreceivedbyaccount.call(deal_name,min_confs)
    log4r.info("Result #{res}")
    res
  end
  
  def self.deal_transactions deal_name, confirmed = true
    log4r.info("Getting transactions for #{deal_name}")
    min_confirms = MIN_CONFIRMS
    min_confirms = 0 if confirmed != true
    log4r.info "CMD listtransactions #{deal_name} 100 #{min_confirms}"
    res = CONN.listtransactions.call deal_name, 100, 0
    res = res.select { |r| r['category'] == 'send' || r['confirmations'] >= min_confirms }
    log4r.info("GOT #{res.inspect}")
    return res
  end

  def self.deal_rake deal_name
    transactions = deal_transactions deal_name, confirmed = false

    received_transactions = transactions.select { |tx| tx['category'] == "receive" && tx['confirmations'] >= MIN_CONFIRMS}
    received_transactions = received_transactions.map { |x| x['amount'] }
    total_received = received_transactions.inject { |a,b| a + b }
    total_received = 0 if total_received.nil?
    log4r.info ("Total received #{total_received}")

    rake_taken = transactions.select { |tx| tx['category'] == "send" && tx["address"] == RAKE_ADDRESS }
      rake_taken = rake_taken.map { |x| x['amount'] }
    total_raked = rake_taken.inject { |a,b| a + b}
    total_raked = 0 if total_raked.nil?
    total_raked = -total_raked
    log4r.info("Total raked #{total_raked}")
    
    hundreds_received = total_received.to_i / 100
    expected_rake = hundreds_received.to_f * RAKE_RATE
    log4r.info("#{hundreds_received} hundreds received.  Expected rake #{expected_rake}")

    if expected_rake > total_raked
      new_rake = expected_rake - total_raked
      log4r.info("Need to rake #{new_rake}")
      log4r.info("cmd: sendfrom #{deal_name}, #{RAKE_ADDRESS}, #{new_rake}")
      CONN.sendfrom.call deal_name, RAKE_ADDRESS, new_rake
    else
      log4r.info("Rake is covered")
    end
  end

  def self.deal_pay deal_name, amount
    deal_rake deal_name

    dest_addr = deal_name.split("_")[-1]
    log4r.info("Address extracted from name is #{dest_addr}")
    
    balance = CONN.getbalance.call deal_name
    log4r.info("Got balance of #{balance}")

    raise "AAAAA" if balance < amount

    log4r.info("We've got enough funds to cover it")

    res = CONN.sendfrom.call deal_name, dest_addr, amount
    log4r.info("Sent #{amount} from #{deal_name} to #{dest_addr}")
    log4r.info("GOT REPLY #{res}")
  end
  
end
