class DealsController < ApplicationController
  def index
    @deals = Deal.find_all_by_user_id(current_user.id)
  end

  def create
    release_address = params[:deal][:release_address]
    #raise params.inspect
    deal_name, address = Bitcoind.new_deal current_user.email, release_address
    Deal.create :user_id => current_user.id, :uuid => deal_name, :send_address => address, :release_address => release_address, :note => params[:deal][:note]

    redirect_to deals_path
  end
  
  def show
    @deal = Deal.find_by_uuid(params[:uuid])
    @deal.sync_books

    @unconfirmed_balance = @deal.line_item_balance
    @confirmed_balance = Bitcoind.deal__unconfirmed_balance @deal.uuid

    if current_user &&  current_user.id == @deal.user_id
      render :show_owner
      return
    end
    
  end
  
end
