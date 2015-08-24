Rails.application.routes.draw do
  root to: 'visitors#index'

  resources :servers do
    post 'launch', on: :collection
  end
  
  get 'visitors/infrastructure', to: 'visitors#infrastructure'
  post 'visitors/deploy', to: 'visitors#deploy', as: :deploy
  post 'visitors/deploy_app', to: 'visitors#deploy_app', as: :deploy_app
end
