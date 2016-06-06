Rails.application.routes.draw do
  devise_for :accounts

  resources :campaigns do
    member do
      get :data
    end

    resources :ads do
      member do
        get :data
      end
    end
  end

  root 'campaigns#index'
end
