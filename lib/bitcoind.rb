module Bitcoind

  CONN = ServiceProxy.new("http://grant:test@127.0.0.1:8332")
  RAKE_RATE = 0.025
  RAKE_ACCOUNT = "the_rake"
  MIN_CONFIRMS = 3
  RESERVE_ACCOUNT = "0d99c148-21fa-4861-9ad8-a05f1f9c24a2"

  
  class BitcoindDown < StandardError;end
  class InvalidBitcoinAddress < StandardError;end
  class BitcoindRefusedRequest < StandardError;end

  def self.log4r
    Log4r::Logger['bitcoind']
  end

  def self.rewrite_exception ex
    if ex.class == Errno::ECONNREFUSED
      raise BitcoindDown, "Unable to process request because the bitcoin daemon is down"
    elsif ex.class == RestClient::InternalServerError
      response = ActiveSupport::JSON.decode(ex.response)
      code = response['error']['code']
      msg = response['error']['message']
      raise BitcoindRefusedRequest, "The bitcoin server refused this request.  Reason: '#{msg}' (#{code})"
    else
      raise ex
    end
  end
  
  
  def self.new_deal user, destination_address
    log4r.info("Validating address #{destination_address}")

    res = CONN.validateaddress.call destination_address
    raise InvalidBitcoinAddress, "You have provided an invalid bitcoin address." if res['isvalid'] == false

    deal_name = UUIDTools::UUID.random_create.to_s
    log4r.info("Creating new deal #{deal_name} for #{user} to #{destination_address}")
    address = CONN.getnewaddress.call deal_name
    log4r.info("Got address #{address}")
    [deal_name, address]
  rescue Exception => ex
    rewrite_exception ex
  end
  
  def self.deal_balance deal_name, confirmed = true
    min_confs = MIN_CONFIRMS
    min_confs = 0 if confirmed == false

    log4r.info("Getting #{confirmed ? "confirmed" : "unconfirmed"} balance for account #{deal_name}...")
    res = CONN.getbalance.call(deal_name,min_confs)
    log4r.info("Result #{res}")
    res
  rescue Exception => ex
    rewrite_exception ex
  end
  
  def self.deal_unconfirmed_balance deal_name
    transactions = deal_transactions deal_name, false
    unconfirmed_recv_txs = transactions.select { |tx| tx['category'] == 'receive' && tx['confirmations'] < MIN_CONFIRMS }

    return 0 if unconfirmed_recv_txs.nil? || unconfirmed_recv_txs.empty?

    amounts = unconfirmed_recv_txs.map { |tx| tx['amount'] }

    res = amounts.reduce { |a,b| a + b}
    res
  rescue Exception => ex
    rewrite_exception ex
  end
  
  def self.deal_unconfirmed_balance_by_confirms deal_name
    transactions = deal_transactions deal_name, false

    results = {}

    transactions.each do |tx|
      next if tx['category'] != 'receive'
      next if tx['confirmations'] >= MIN_CONFIRMS

      confirm = MIN_CONFIRMS - tx['confirmations']
      amount = tx['amount']

      results[confirm] = 0.0 if !results.has_key?(confirm)
      results[confirm] += amount
    end
    
    results = results.to_a.sort { |a,b| a[0] <=> b[0] }
    results.reverse
  end
  

  def self.deal_transactions deal_name, confirmed = true
    log4r.info("Getting transactions for #{deal_name}")
    min_confirms = MIN_CONFIRMS
    min_confirms = 0 if confirmed != true
    log4r.info "CMD listtransactions #{deal_name} 100 #{min_confirms}"
    res = CONN.listtransactions.call deal_name, 100, 0
    res = res.select { |r| r['category'] == 'send' || r['category'] == 'move' || r['confirmations'] >= min_confirms }
    log4r.info("GOT #{res.inspect}")
    return res
  rescue Exception => ex
    rewrite_exception ex
  end

  def self.deal_rake deal_name
    transactions = deal_transactions deal_name, confirmed = false

    received_transactions = transactions.select { |tx| tx['category'] == "receive" && tx['confirmations'] >= MIN_CONFIRMS}
    received_transactions = received_transactions.map { |x| x['amount'] }
    total_received = received_transactions.inject { |a,b| a + b }
    total_received = 0 if total_received.nil?
    log4r.info ("Total received #{total_received}")

    rake_taken = transactions.select { |tx| tx['category'] == "move" && tx["otheraccount"] == RAKE_ACCOUNT }
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
      log4r.info("cmd: move #{deal_name}  #{RAKE_ACCOUNT}, #{new_rake}")
      CONN.move.call deal_name, RAKE_ACCOUNT, new_rake
    else
      log4r.info("Rake is covered")
    end
  rescue Exception => ex
    rewrite_exception ex
  end

  def self.deal_pay deal_name, dest_addr,  amount
    deal_rake deal_name

    log4r.info("Address extracted from name is #{dest_addr}")
    
    log4r.info("cmd sendfrom #{RESERVE_ACCOUNT} #{dest_addr} #{amount} #{MIN_CONFIRMS}")
    res = CONN.sendfrom.call RESERVE_ACCOUNT, dest_addr, amount.to_f, MIN_CONFIRMS
    log4r.info("Sent #{amount} from #{deal_name} to #{dest_addr}")
    log4r.info("GOT REPLY #{res}")
  rescue Exception => ex
    rewrite_exception ex
  end
  
  def self.deal_move_deposit deal_name, amount, tx
    log4r.info "Moving #{amount} from #{deal_name} to reserve..."
    CONN.move.call deal_name, RESERVE_ACCOUNT, amount, MIN_CONFIRMS, tx 
  end

  def self.wallet_balance
    log4r.info "Getting Wallet balance..."
    CONN.getbalance.call
  end
  
end
