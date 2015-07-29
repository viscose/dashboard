Rails.application.routes.draw do
  root to: 'visitors#index'
  
  get 'visitors/infrastructure', to: 'visitors#infrastructure'
  post 'visitors/deploy', to: 'visitors#deploy', as: :deploy
end
