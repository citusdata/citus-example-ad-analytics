Rails.application.routes.draw do
  devise_for :accounts

  resources :campaigns do
    member do
      get :stats
    end

    resources :ads do
      member do
        get :stats
      end
    end
  end

  root 'pages#index'
end
