DulHydra::Application.routes.draw do

  PID_CONSTRAINT = { id: /[a-zA-Z0-9\-_]+:[a-zA-Z0-9\-_]+/ }

  root :to => "catalog#index"

  Blacklight.add_routes(self)

  devise_for :users

  mount FcrepoAdmin::Engine => '/fcrepo', as: 'fcrepo_admin'

  resources :objects, only: [:show], constraints: PID_CONSTRAINT do
    member do
      get 'collection_info'
      get 'download' => 'downloads#show'
      get 'preservation_events'
      get 'thumbnail' => 'thumbnail#show'
      get 'datastreams/:datastream_id' => 'downloads#show', as: 'download_datastream'
    end
  end

  # hydra-editor for descriptive metadata
  resources :objects, only: [:edit, :update], as: 'records', constraints: PID_CONSTRAINT
    
  resources :preservation_events, :only => :show, constraints: { id: /[1-9][0-9]*/ }

  resources :export_sets do
    member do
      post 'archive'
      delete 'archive'
    end
  end
  
  resources :batches do
    member do
      get 'procezz'
      get 'validate'
    end
    resources :batch_runs
    resources :batch_objects do
      resources :batch_object_datastreams
      resources :batch_object_relationships
    end
  end

  resources :admin_policies, :only => [:edit, :update], constraints: PID_CONSTRAINT
  
end
