class Admin::TemplatesController < Admin::AdminController
  before_action :require_sysadmin, only: [:new, :edit, :create, :destroy]
  before_action :find_templates, only: [:index]
  before_action :find_template, only: [:show, :edit, :update, :destroy]
  before_action :build_template, only: [:new, :create]

  def index
    respond_to do |format|
      format.html
    end
  end

  def create
    if @template.save
      redirect_to_index_url notice: :template_created
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @template.update(template_params)
      redirect_to_index_url notice: :template_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    if @template.destroy
      redirect_to_index_url notice: :template_deleted
    else
      redirect_to_index_url alert: :template_not_deleted
    end
  end

  private

  def find_templates
    @templates = Notifications::Template.search(search_params)
  end

  def find_template
    @template = Notifications::Template.find(template_id)
  end

  def build_template
    @template = Notifications::Template.new(template_params)
  end

  def search_params
    params.permit(:q, :page, :count)
  end

  def template_id
    params.require(:id)
  end

  def template_params
    if params.key?(:template)
      params.require(:template).permit(:name, :subject, :body)
    else
      {}
    end
  end

  def index_url
    admin_templates_url(params.permit(:q))
  end

  def redirect_to_index_url(options = {})
    redirect_to index_url, options
  end
end
