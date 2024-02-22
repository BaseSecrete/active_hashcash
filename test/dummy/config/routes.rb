Rails.application.routes.draw do
  resource :session, only: [:create]
  mount ActiveHashcash::Engine => "/active_hashcash"
end
