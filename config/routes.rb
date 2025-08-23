# encoding: UTF-8
# config/routes.rb
Rails.application.routes.draw do
  # Auth
  get  "/signup", to: "users#new",    as: :signup
  post "/signup", to: "users#create"
  get  "/login",  to: "sessions#new",  as: :login
  post "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :xml_documents do
    member do
      get :download
    end
  end

  namespace :api do
    resources :xml_documents, only: [:index]
  end
  
  root 'xml_documents#index'
end