class RegionsController < LocalizedController
  before_action :set_parliament
  before_action :set_cors_headers, if: :json_request?

  skip_forgery_protection

  def index
    @regions = @parliament.regions.all

    respond_to do |format|
      format.json
      format.geojson
      format.js
    end
  end

  private

  def set_parliament
    if params.key?(:parliament)
      @parliament = Parliament.find!(params[:parliament])
    else
      @parliament = Parliament.current
    end
  end
end
