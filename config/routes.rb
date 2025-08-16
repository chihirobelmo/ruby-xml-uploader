# encoding: UTF-8
# config/routes.rb
Rails.application.routes.draw do
  resources :xml_documents do
    member do
      get :download
    end
  end
  
  root 'xml_documents#index'
end