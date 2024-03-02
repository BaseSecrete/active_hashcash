ActiveHashcash::Engine.routes.draw do
  resources :assets, only: [:show]
  resources :stamps, only: [:index, :show]
  root "stamps#index"
end
