class TransactionsController < ApplicationController
  def index
    @txs = Transactions.find_all_by_user_id(current_user.id)
  end

  def create
    release_address = params[:transaction][:release_address]
    #raise params.inspect
    deal_name, address = Bitcoind.new_deal current_user.email, release_address
    Transactions.create :user_id => current_user.id, :tx_id => deal_name, :release_address => address, :note => params[:transaction][:note]

    redirect_to transactions_path
  end
  
end
