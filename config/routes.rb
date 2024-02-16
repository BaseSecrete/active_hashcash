ActiveHashcash::Engine.routes.draw do
  resources :assets, only: [:show]
  resources :stamps, only: [:index]
  root "stamps#index"
end
