Rails.application.routes.draw do
  resource :session, only: [:show, :create]
  mount ActiveHashcash::Engine => "/active_hashcash"
end
