Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  devise_for :users, skip: [ :sessions, :registrations ],
    controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    get "sign-in", to: "devise/sessions#new", as: :new_user_session
    post "sign-in", to: "devise/sessions#create", as: :user_session
    delete "logout", to: "devise/sessions#destroy", as: :destroy_user_session

    get "signup", to: "users/registrations#new", as: :new_user_registration
    post "signup", to: "users/registrations#create", as: :user_registration
    delete "signup", to: "users/registrations#destroy"

    get "settings", to: "users/registrations#edit", as: :edit_user_registration
    patch "settings", to: "users/registrations#update", as: :update_user_registration
    put "settings", to: "users/registrations#update"
  end

  scope "/app" do
    root to: "dashboards#show", as: :authenticated_root

    resources :plans, path: "planner" do
      resource :share, only: [ :show, :create, :destroy ], controller: "plan_shares"
      member do
        get :confirm_delete
        patch :move
      end
    end

    get "inventory/quick", to: "inventory_quick_entries#show", as: :inventory_quick_entry
    patch "inventory/quick", to: "inventory_quick_entries#update"
    get "inventory/export", to: "inventory_exports#show", as: :inventory_export
    get "inventory/import", to: "inventory_imports#new", as: :new_inventory_import
    post "inventory/import", to: "inventory_imports#create", as: :inventory_import
    resources :inventory_items, only: [ :index, :edit, :update ], path: "inventory"
    resources :api_keys, only: [ :create, :destroy ]
    resources :identities, only: :destroy

    get "optimizer", to: "optimizers#index"
    get "optimizer/plans_modal", to: "optimizers#plans_modal"
    post "optimizer/select_plan", to: "optimizers#select_plan"
    get "optimizer/advise", to: "optimizers#advise"
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :plans, only: [ :index, :create ] do
        member do
          get :reconciliation
          get :waveplate_summary, path: "waveplate-summary"
        end
      end

      resources :inventory, only: [ :index ]
      resources :materials, only: [ :index ]

      patch "profile", to: "profile#update"

      match "*path", to: "base#handle_not_found", via: :all
    end
  end

  get "p/:token", to: "shared_plans#show", as: :shared_plan, constraints: { token: /[A-Za-z0-9_-]{16,64}/ }
  get "user-manual", to: "pages#user_manual", as: :user_manual
  get "privacy", to: "pages#privacy", as: :privacy

  # Defines the root path route ("/")
  root "pages#home"
end
