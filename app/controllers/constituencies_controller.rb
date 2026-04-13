class ConstituenciesController < LocalizedController
  before_action :set_parliament
  before_action :set_cors_headers, if: :json_request?

  skip_forgery_protection

  def index
    @constituencies = @parliament.constituencies.all

    respond_to do |format|
      format.json
      format.geojson
      format.js
    end
  end

  def set_parliament
    if params.key?(:parliament)
      @parliament = Parliament.find!(params[:parliament])
    else
      @parliament = Parliament.current
    end
  end
end
