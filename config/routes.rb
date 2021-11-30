Rails.application.routes.draw do
  root to: 'calculator#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :calculator, only: [:index, :new]
  post 'calculator/new', to: 'calculator#create'
  get 'calculator/download', to: 'calculator#download'

end
