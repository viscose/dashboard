Rails.application.routes.draw do
  get 'components/deploy'

  get 'components/undeploy'

  root to: 'visitors#index'

  resources :servers do
    post 'launch', on: :collection
  end
  
  resources :components do
    post 'deploy'
    post 'undeploy'
    post 'execute_steps'
  end
  
  get 'visitors/infrastructure', to: 'visitors#infrastructure'
  post 'visitors/deploy', to: 'visitors#deploy', as: :deploy
  post 'visitors/deploy_app', to: 'visitors#deploy_app', as: :deploy_app
end
