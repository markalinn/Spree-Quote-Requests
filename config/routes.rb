Rails.application.routes.draw do
  # Add your extension routes here
  # non-restful admin checkout stuff
  match '/admin/quote_requests/:quote_request_number/checkout' => 'admin/checkout#update', :method => :post, :as => :admin_quote_requests_checkout
  match '/admin/quote_requests/:quote_request_number/checkout/(:state)' => 'admin/checkout#edit', :method => :get, :as => :admin_quote_requests_checkout

  resources :quote_requests do
    post :populate, :on => :collection

    resources :quote_request_line_items
  end
  
  namespace :admin do
    resources :quote_requests do
      member do
        put :fire
        get :fire
        post :resend
        get :history
        get :user
      end    
      resources :quote_request_line_items
    end
  end
end
