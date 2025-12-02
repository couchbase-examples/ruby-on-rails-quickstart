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
      # Health check endpoint
      get 'health', to: 'health#show'

      # Airlines resource routes
      get 'airlines/list', to: 'airlines#index'
      get 'airlines/to-airport', to: 'airlines#to_airport'
      get 'airlines/:id', to: 'airlines#show'
      post 'airlines/:id', to: 'airlines#create'
      put 'airlines/:id', to: 'airlines#update'
      delete 'airlines/:id', to: 'airlines#destroy'

      # Airports resource routes
      get 'airports/direct-connections', to: 'airports#direct_connections'
      get 'airports/:id', to: 'airports#show'
      post 'airports/:id', to: 'airports#create'
      put 'airports/:id', to: 'airports#update'
      delete 'airports/:id', to: 'airports#destroy'

      # Routes resource routes
      get 'routes/:id', to: 'routes#show'
      post 'routes/:id', to: 'routes#create'
      put 'routes/:id', to: 'routes#update'
      delete 'routes/:id', to: 'routes#destroy'

      #Hotel resource routes
      get 'hotels/autocomplete', to: 'hotels#search'
      post 'hotels/filter', to: 'hotels#filter'
    end
  end
end
