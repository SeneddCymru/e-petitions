class ApplicationController < ActionController::Base
  protect_from_forgery with: :reset_session

  before_action :reload_site
  before_action :redirect_to_url_without_format, if: :unknown_format?

  def admin_request?
    false
  end

  protected

  def csv_request?
    request.format.symbol == :csv
  end

  def json_request?
    request.format.symbol == :json || request.format.symbol == :geojson
  end

  def unknown_format?
    request.format.nil?
  end

  def url_without_format
    URI.parse(request.original_url).tap do |uri|
      uri.path = File.join(File.dirname(request.path), File.basename(request.path, '.*'))
    end.to_s
  rescue URI::InvalidURIError => e
    home_url
  end

  def redirect_to_url_without_format
    redirect_to url_without_format
  end

  def reload_site
    Site.reload
  end

  def redirect_to_home_page
    redirect_to home_url
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept'
  end

  def do_not_cache
    response.headers['Cache-Control'] = 'no-store'
  end

  def current_time
    Time.current.getutc.iso8601
  end
end
