class DealsController < ApplicationController
  def index
    @deals = Deal.find_all_by_user_id(current_user.id)
  end

  def create
    release_address = params[:deal][:release_address]
    #raise params.inspect
    deal_name, address = Bitcoind.new_deal current_user.email, release_address
    deal = Deal.create :user_id => current_user.id, :uuid => deal_name, :send_address => address, :release_address => release_address, :note => params[:deal][:note]

    redirect_to deal_path deal.uuid
  rescue Bitcoind::BitcoindDown, Bitcoind::InvalidBitcoinAddress => ex
    flash.now[:alert] = "ERROR: " + ex.message
    @deals = Deal.find_all_by_user_id(current_user.id)

    render :index
  end
  
  def show
    @deal = Deal.find_by_uuid(params[:uuid])
    @deal.move_deposits_to_reserve
    @deal.take_rake

    begin
      @unconfirmed_balance = Bitcoind.deal_unconfirmed_balance @deal.uuid
    rescue Bitcoind::BitcoindDown => ex
      @unconfirmed_balance = "????"
    end
    
    @confirmed_balance = @deal.line_item_balance

    if current_user &&  current_user.id == @deal.user_id
      render :show_owner
      return
    end
    
  end
  
  def release
    deal = Deal.find_by_uuid(params[:uuid])
    coins = params[:release_amount]
    deal.release coins
    flash[:alert] = "Released #{coins} to #{deal.release_address}..."
    redirect_to deals_path
  rescue Deal::ReleaseFundsError, Bitcoind::BitcoindRefusedRequest => ex
    flash[:alert] = "ERROR: #{ex.message}"
    redirect_to deal_path(deal.uuid)

  end
  
end
