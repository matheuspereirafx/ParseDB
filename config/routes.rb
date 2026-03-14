Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  resources :stacks, only: [ :index, :show ] do
    resources :chats, only: [ :create ]
  end

  # Mínimo necessário para chats funcionarem
  resources :chats, only: [ :index, :show, :new, :create ] do
    resources :messages, only: [ :create ]
    resource :multi_modal, only: [ :create ], controller: "multi_modal"
  end
end
