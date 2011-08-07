class ApiController < ApplicationController
  def log4r
    Log4r::Logger['api']
  end

  def create
    if user = auth_user
      release_address = params['release_address']
      note = params['note']

      deal_name, address = Bitcoind.new_deal user.email, release_address
      deal = Deal.create :user_id => user.id, :uuid => deal_name, :send_address => address, :release_address => release_address, :note => note

      render :text => ({:deal => deal.uuid}.to_json) , :status => 200
    end
    
  end
  
  def deal_info
    if user = auth_user
      uuid = params['uuid']
      deal = get_deal

      unconfirmed_balance = Bitcoind.deal_unconfirmed_balance_by_confirms uuid

      deal_info = { :uuid => deal.uuid, :release_address => deal.release_address,
        :note => deal.note, :send_address => deal.send_address, :balance => deal.line_item_balance, :unconfirmed_balance => unconfirmed_balance}
      
      render :text => ({:deal => deal_info}.to_json), :status => 200
    end
  end

  def list_deals
    if user = auth_user
      uuids = Deal.find_all_by_user_id(user.id).map { |d| d.uuid }
      render :text => {:deals => uuids}.to_json, :status => 200
    end
  end

  def release_funds
    if user = auth_user
      deal = get_deal
      amount = params["amount"]
      deal.release amount.to_f

      render :text => {:amount => amount}, :status => 200
    end
  end
  
  protected

  def auth_user
    email = params['email']
    api_key = params['api_key']

    log4r.info("Authenticating #{email.inspect}...")

    user = User.find_by_email(email)
    if user.nil? || api_key.nil? || api_key.empty? || user.api_key != api_key
      render :text => "Forbidden", :status => 403
      return nil
    else
      return user
    end
  end

  def get_deal
    uuid = params['uuid']
    deal = Deal.find_by_uuid(uuid)

    deal.move_deposits_to_reserve
    deal.take_rake
    
    deal
  end
  
end
