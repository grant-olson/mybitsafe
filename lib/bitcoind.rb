module Bitcoind
  CONN = ServiceProxy.new("http://grant:test@127.0.0.1:8332")

  def self.log4r
    Log4r::Logger['bitcoind']
  end
  
  def self.new_deal user, destination_address
    log4r.info("Validating address #{destination_address}")
    CONN.validateaddress.call destination_address
    deal_name = "#{user}_#{destination_address}"
    log4r.info("Creating new deal for #{user} to #{destination_address}")
    address = CONN.getnewaddress.call deal_name
    log4r.info("Got address #{address}")
    [deal_name, address]
  end
  
  def self.deal_balance deal_name, confirmed = true
    min_confs = 1
    min_confs = 0 if confirmed == false

    log4r.info("Getting #{confirmed ? "confirmed" : "unconfirmed"} balance for account #{deal_name}...")
    res = CONN.getreceivedbyaccount.call(deal_name,min_confs)
    log4r.info("Result #{res}")
    res
  end
  
end
