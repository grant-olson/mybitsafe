class TransactionsController < ApplicationController
  def index
    @txs = Transactions.find(:all)
  end

  def create
    release_address = params[:transaction][:release_address]
    #raise params.inspect
    deal_name, address = Bitcoind.new_deal current_user.email, release_address
    Transactions.create :tx_id => deal_name, :release_address => address

    redirect_to transactions_path
  end
  
end
