Rails.application.routes.draw do
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get 'sessions/new'
  namespace :admin do
    resources :users
  end
    root to: 'tasks#index'
    resources :tasks do
      post :confirm, action: :confirm_new, on: :new
      post :import, on: :collection
    end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
