module ActionDispatch::Routing
  class Mapper
    def mount_activeadmin_settings
      scope '/admin', module: "activeadmin_settings", as: 'admin' do
        # scope "redactor" do
        #   resources :pictures, only: [:index, :create], controller: 'redactor/pictures'
        # end
        resources :settings, only: [:update], controller: 'settings'
        resources :admin_users, only: [:create, :update, :destroy], controller: 'admin_users'
      end
    end
  end
end
