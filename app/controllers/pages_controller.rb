class PagesController < LocalizedController
  before_action :raise_routing_error, only: :contact, unless: :feedback_disabled?

  def index
    respond_to do |format|
      format.html
    end
  end

  def accessibility
    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end

  def help
    respond_to do |format|
      format.html
    end
  end

  def holding
    respond_to do |format|
      format.html
    end
  end

  def privacy
    respond_to do |format|
      format.html
    end
  end

  def rules
    respond_to do |format|
      format.html
    end
  end

  def browserconfig
    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end

  def manifest
    expires_in 1.hour, public: true

    respond_to do |format|
      format.json
    end
  end
end
