class LocalizedController < ApplicationController
  include FlashI18n

  if ENV['TRANSLATION_ENABLED'].present?
    before_action do
      Language.reload_translations
    end
  end

  before_action :set_locale
  before_action :service_unavailable, unless: :site_enabled?
  before_action :authenticate, if: :site_protected?
  before_action :set_bypass_cookie, if: :bypass_param?
  before_action :redirect_to_holding_page

  helper_method :holding_page?
  helper_method :public_petition_facets

  content_security_policy do |policy|
    if Site.translation_enabled?
      policy.script_src :self, :unsafe_inline,
        "https://cc.cdn.civiccomputing.com",
        "https://www.googletagmanager.com",
        "https://www.google-analytics.com",
        Site.moderate_url
    end
  end

  private

  def authenticate
    unless authenticated?
      if request.format.html?
        redirect_to login_url
      else
        head :forbidden
      end
    end
  end

  def authenticated?
    cookies[:login] == Site.login_digest
  end

  def service_unavailable
    unless authenticated?
      raise Site::ServiceUnavailable, "Sorry, the website is temporarily unavailable"
    end
  end

  def site_enabled?
    Site.enabled?
  end

  def site_protected?
    Site.protected? unless request.local?
  end

  def public_petition_facets
    I18n.t('public', scope: :"petitions.facets")
  end

  def set_locale
    I18n.locale = locale
  end

  def locale
    case params[:locale]
    when "cy-GB"
      :"cy-GB"
    else
      :"en-GB"
    end
  end

  def holding_page?
    controller_name == "pages" && action_name == "holding"
  end

  def bypass_param?
    params.key?(:bypass)
  end

  def bypass_param
    params[:bypass]
  end

  def bypass_cookie
    cookies.signed[:_wpets_bypass]
  end

  def bypass_authenticated?
    Site.bypass_token? && Site.bypass_token == bypass_cookie
  end

  def set_bypass_cookie
    if bypass_param == Site.bypass_token
      cookies.signed[:_wpets_bypass] = Site.bypass_token
      redirect_to home_url
    end
  end

  def redirect_to_holding_page
    unless bypass_authenticated?
      redirect_to holding_url if Site.show_holding_page?
    end
  end
end
