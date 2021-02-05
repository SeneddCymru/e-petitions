Rails.application.routes.draw do
  extend ScotsPets::Routing

  public_scope do
    scope controller: 'constituencies' do
      get '/constituencies', action: 'index', as: :constituencies
    end

    scope controller: 'topics' do
      get '/topics', action: 'index', as: :topics
    end

    scope controller: 'pages' do
      get '/',        action: 'index',   as: :home
      get '/help',    action: 'help',    as: :help
      get '/privacy', action: 'privacy', as: :privacy
      get '/rules',   action: 'rules',   as: :rules

      get '/accessibility', action: 'accessibility', as: :accessibility

      get '/coming-soon', action: 'holding', as: :holding

      scope format: true, localized: false do
        get '/browserconfig', action: 'browserconfig', as: :browserconfig, constraints: { format: 'xml' }
        get '/manifest',      action: 'manifest',      as: :manifest,      constraints: { format: 'json' }
      end
    end

    scope '/feedback', controller: 'feedback' do
      get  '/',       action: 'new',    as: :feedback
      post '/',       action: 'create', as: :create_feedback
      get  '/thanks', action: 'thanks', as: :thanks_feedback
    end

    scope '/petitions/local', controller: 'local_petitions' do
      get  '/',        action: 'index', as: :local_petitions
      get  '/:id',     action: 'show',  as: :local_petition
      get  '/:id/all', action: 'all',   as: :all_local_petition
    end

    scope '/petitions', controller: 'petitions' do
      get  '/check',         action: 'check',         as: :check_petitions
      get  '/check-results', action: 'check_results', as: :check_results_petitions
      post '/new',           action: 'create',        as: :create_petition
      get  '/thank-you',     action: 'thank_you',     as: :thank_you_petitions

      scope '/:id', constraints: { id: /(PE|PP)\d{1,11}/ } do
        get '/count',             action: 'count',             as: :count_petition
        get '/gathering-support', action: 'gathering_support', as: :gathering_support_petition
        get '/moderation-info',   action: 'moderation_info',   as: :moderation_info_petition
      end

      scope '/:petition_id', constraints: { id: /PP\d{1,11}/ } do
        scope '/sponsors', controller: 'sponsors' do
          post '/new',       action: 'confirm',   as: :confirm_petition_sponsors
          get  '/thank-you', action: 'thank_you', as: :thank_you_petition_sponsors
          post '/',          action: 'create',    as: :petition_sponsors
          get  '/new',       action: 'new',       as: :new_petition_sponsor
        end
      end

      scope '/:petition_id', constraints: { id: /PE\d{1,11}/ } do
        scope '/signatures', controller: 'signatures' do
          post '/new',       action: 'confirm',   as: :confirm_petition_signatures
          get  '/thank-you', action: 'thank_you', as: :thank_you_petition_signatures
          post '/',          action: 'create',    as: :petition_signatures
          get  '/new',       action: 'new',       as: :new_petition_signature
        end
      end

      get '/',    action: 'index', as: :petitions
      get '/new', action: 'new',   as: :new_petition
      get '/:id', action: 'show',  as: :petition, constraints: { id: /(PE|PP)\d{1,11}/ }
    end

    scope '/petitioners', controller: 'petitioners' do
      get '/:id/verify', action: 'verify', as: :verify_petitioner
      get '/:id/thank-you', action: 'thank_you', as: :thank_you_petitioner
    end

    scope '/sponsors', controller: 'sponsors' do
      get '/:id/verify',    action: 'verify', as: :verify_sponsor
      get '/:id/sponsored', action: 'signed', as: :signed_sponsor
    end

    scope '/signatures', controller: 'signatures' do
      get '/:id/verify',      action: 'verify',      as: :verify_signature
      get '/:id/unsubscribe', action: 'unsubscribe', as: :unsubscribe_signature
      get '/:id/signed',      action: 'signed',      as: :signed_signature
    end
  end

  moderation_scope do
    get '/', to: redirect('/admin')

    namespace :admin do
      mount Delayed::Web::Engine, at: '/delayed'

      root to: 'admin#index'

      resource :search, only: %i[show]

      resources :admin_users
      resources :profile, only: %i[edit update]
      resources :user_sessions, only: %i[create]

      resources :languages, only: %i[index show], param: 'locale' do
        member do
          post :reload

          constraints key: /[-_a-z0-9.]+/ do
            scope format: false do
              get    '/:key', action: 'edit', as: :edit
              patch  '/:key', action: 'update', as: :update
              delete '/:key', action: 'destroy', as: :destroy
            end
          end
        end
      end

      get '/translations', to: 'translations#index', as: :translations

      resources :invalidations, except: %i[show] do
        post :cancel, :count, :start, on: :member
      end

      resources :paper_petitions, only: %i[new create]

      resources :petitions, only: %i[show index], constraints: { id: /(PE|PP)?\d{1,11}/ } do
        post :resend, on: :member

        resources :emails, controller: 'petition_emails', except: %i[show]
        resource  :lock, only: %i[show create update destroy]
        resource  :moderation, controller: 'moderation', only: %i[update]
        resource  :statistics, controller: 'petition_statistics', only: %i[update]
        resources :trending_ips, path: 'trending-ips', only: %i[index]
        resources :trending_domains, path: 'trending-domains', only: %i[index]

        scope only: %i[show update] do
          resource :abms_link, path: 'abms-link', controller: 'abms_link'
          resource :completion_date, path: 'completion-date', controller: 'completion_date'
          resource :debate_outcome, path: 'debate-outcome'
          resource :notes
          resource :details, controller: 'petition_details'
          resource :schedule_debate, path: 'schedule-debate', controller: 'schedule_debate'
          resource :tags, controller: 'petition_tags'
          resource :take_down, path: 'take-down', controller: 'take_down'
          resource :topics, controller: 'petition_topics'
        end

        resource :completion, controller: 'completion', only: %i[update]
        resource :archive, controller: 'archive', only: %i[update]

        resources :signatures, except: %i[show edit update] do
          post :validate, :invalidate, on: :member
          post :subscribe, :unsubscribe, on: :member

          collection do
            delete :destroy, action: :bulk_destroy
            post   :validate, action: :bulk_validate
            post   :invalidate, action: :bulk_invalidate
            post   :subscribe, action: :bulk_subscribe
            post   :unsubscribe, action: :bulk_unsubscribe
          end
        end
      end

      resources :domains, except: %i[show]
      resources :rejection_reasons, path: 'rejection-reasons', except: %i[show]

      resource :rate_limits, path: 'rate-limits', only: %i[edit update]
      resource :site, only: %i[edit update]
      resource :holidays, only: %i[edit update]

      resources :signatures, only: %i[index destroy] do
        post :validate, :invalidate, on: :member
        post :subscribe, :unsubscribe, on: :member

        collection do
          delete :destroy, action: :bulk_destroy
          post   :validate, action: :bulk_validate
          post   :invalidate, action: :bulk_invalidate
          post   :subscribe, action: :bulk_subscribe
          post   :unsubscribe, action: :bulk_unsubscribe
        end

        resource :logs, only: :show
      end

      resources :tags, except: %i[show]
      resources :topics, except: %i[show]

      scope 'stats', controller: 'statistics' do
        get '/', action: 'index', as: :stats
        get '/moderation/:period', action: 'moderation', as: :moderation_stats, period: /week|month/
      end

      controller 'user_sessions' do
        get '/logout',   action: 'destroy'
        get '/login',    action: 'new'
        get '/continue', action: 'continue'
        get '/status',   action: 'status'
      end
    end
  end

  get 'ping', to: 'ping#ping'
end
