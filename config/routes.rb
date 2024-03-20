# Rails.application.routes.draw do
#   # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

#   # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
#   # Can be used by load balancers and uptime monitors to verify that the app is live.
#   get "up" => "rails/health#show", as: :rails_health_check

#   # Defines the root path route ("/")
#   # root "posts#index"
# end

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      get 'airlines/list', to: 'airlines#index'
      get 'airlines/to-airport', to: 'airlines#to_airport'
      resources :airlines, only: [:show, :create, :update, :destroy], param: :id
      get 'airports/direct-connections', to: 'airports#direct_connections'
      resources :airports, only: [:show, :create, :update, :destroy], param: :id
      resources :routes, only: [:show, :create, :update, :destroy], param: :id
    end
  end
end
