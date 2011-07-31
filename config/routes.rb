Bestcrow::Application.routes.draw do
  devise_for :users, :controllers => { :registrations => "registrations" }

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

#  resources :deals
  match '/deals(.:format)', :controller => :deals, :action => :index, :as => :deals, :via => :get
  match '/deals(.:format)', :controller => :deals, :action => :create, :via => :post
  match '/deals/new(.:format)', :controller => :deals, :action => :new, :as => :new_deal, :via => :get
  match '/deals/track', :controller => :deals, :action => :track, :as => :deal_track
  match '/deals/:uuid(.:format)', :controller => :deals, :action => :show, :as => :deal, :via => :get
  match '/deals/:uuid/release', :controller => :deals, :action => :release, :as => :deal_release , :via => :put

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  match '/terms_of_service', :controller => :home, :action => :terms_of_service, :as => :terms_of_service, :via => :get
  match '/fees', :controller => :home, :action => :fees, :as => :fees, :via => :get
  match '/faq', :controller => :home, :action => :faq, :as => :faq, :via => :get
  match '/need_confirmation', :controller => :home, :action => :need_confirmation, :as => :need_confirmation, :via => :get
  root :to => "home#index"
end
