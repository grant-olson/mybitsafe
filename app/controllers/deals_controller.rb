class DealsController < ApplicationController
  def index
    @deals = Deals.find_all_by_user_id(current_user.id)
  end

  def create
    release_address = params[:deal][:release_address]
    #raise params.inspect
    deal_name, address = Bitcoind.new_deal current_user.email, release_address
    Deals.create :user_id => current_user.id, :tx_id => deal_name, :send_address => address, :release_address => release_address, :note => params[:deal][:note]

    redirect_to deals_path
  end
  
  def show
    @deal = Deals.find(params[:id])
    @unconfirmed_balance = Bitcoind.deal_balance @deal.tx_id, false
    @confirmed_balance = Bitcoind.deal_balance @deal.tx_id, true

    if current_user &&  current_user.id == @deal.user_id
      render :show_other
      return
    end
    
  end
  
end
