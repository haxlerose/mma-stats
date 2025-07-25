Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :events, only: [:index, :show]
      resources :fighters, only: [:index, :show]
      resources :fights, only: [:show]
      resources :fighter_spotlight, only: [:index]
      resources :statistical_highlights, only: [:index]
      resources :locations, only: [:index]
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
