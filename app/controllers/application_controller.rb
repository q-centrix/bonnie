class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!
  before_filter :log_additional_data
  layout :layout_by_resource

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def after_sign_out_path_for(resource)
    "#{(respond_to?(:root_path) ? root_path : "/")}users/sign_in"
  end

  protected
    def log_additional_data
      request.env["exception_notifier.exception_data"] = {
        :current_user => current_user
      }
    end

  private
    def authenticate_user_from_token!
      authenticate_with_http_token do |token, options|
        user_email = options[:email].presence
        user = user_email && User.find_by(email: user_email)

        if user && Devise.secure_compare(user.authentication_token, token)
          sign_in user, store: false
        end
      end
    end
end
