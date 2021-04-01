class Member < ActiveRecord::Base
  URL_EN = "https://www.parliament.scot/msps/current-and-previous-msps/%{slug}"
  URL_GD = "https://www.parlamaid-alba.scot/msps/current-and-previous-msps/%{slug}"

  MEMBER_PATTERN = / (?:MSP|BPA)$/

  include Translatable

  translate :name, :party

  belongs_to :region, optional: true
  belongs_to :constituency, optional: true

  default_scope { order(:name) }

  with_options prefix: true, allow_nil: true do
    delegate :name, to: :region
    delegate :name, to: :constituency
  end

  class << self
    def for(id, &block)
      find_or_initialize_by(id: id).tap(&block)
    end
  end

  def slug
    name.gsub(MEMBER_PATTERN, '').parameterize
  end

  def url
    I18n.locale == :"gd-GB" ? url_gd : url_en
  end

  private

  def url_en
    URL_EN % { slug: slug }
  end

  def url_gd
    URL_GD % { slug: slug }
  end
end
