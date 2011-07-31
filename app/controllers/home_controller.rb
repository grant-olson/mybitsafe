class HomeController < ApplicationController
  layout "application"

  def index
    @title = "Affordable Bitcoin Escrow - 0.025 BTC for Most Deals."
  end

  def terms_of_service
    @title = "Terms of Service"
  end

  def fees
    @title = "Fee Schedule"
  end
  
  def faq
    @title = "Frequently Asked Questions"
  end

  def need_confirmation
    @title = "Awaiting email confirmation"
  end
  
end
