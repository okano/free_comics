Rails.application.routes.draw do
  get 'static_pages/about'
  root 'series#index'
  get 'series/index'
  get 'series/:id', to: 'series#show'
end
