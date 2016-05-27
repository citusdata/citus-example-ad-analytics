Rails.application.routes.draw do
  devise_for :accounts

  resources :campaigns do
    resources :ads
  end

  root 'pages#index'
end
