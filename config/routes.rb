# config/routes.rb
Rails.application.routes.draw do
  devise_for :users

  root "pages#home"

  # Apenas stacks com UM chat cada
  resources :stacks do
    # Singular: UM chat por stack
    resource :chat, only: [ :show ] do
      resources :messages, only: [ :create ]
    end
  end

  # NÃO temos mais rotas globais para chats
  # (removido resources :chats)
end
