class LocalizedController < ApplicationController
  include FlashI18n

  if ENV['TRANSLATION_ENABLED'].present?
    before_action do
      Language.reload_translations
    end
  end

  before_action :set_locale
  before_action :set_bypass_cookie, if: :bypass_param?
  before_action :redirect_to_holding_page

  helper_method :holding_page?

  private

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
