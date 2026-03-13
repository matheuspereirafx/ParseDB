Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  resources :stacks, only: [:index, :show] do
    resources :chats, only: [:create, :index, :show, :new] do
      resources :messages, only: [:create]
    end
  end
end
