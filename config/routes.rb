Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  # Rotas para Stacks com chats aninhados
  resources :stacks, only: [ :index, :show ] do
    resources :chats, only: [ :index, :show, :create ] do  # ✅ Adicione :show aqui
      resources :messages, only: [ :create ]
    end
  end

  # Rotas globais para chats (sem stack aninhado)
  resources :chats, only: [ :index, :show, :new, :create ] do
    resources :messages, only: [ :create ]
    resource :multi_modal, only: [ :create ], controller: "multi_modal"
  end
end
