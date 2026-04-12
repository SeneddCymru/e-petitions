class Member < ActiveRecord::Base
  URL_EN = "https://senedd.wales/people/%{slug}/"
  URL_CY = "https://senedd.cymru/pobl/%{slug}/"

  PARTY_COLOURS = {
    'Plaid Cymru' => '#008672',
    'Reform UK' => '#12B6CF',
    'Reform UK Wales' => '#12B6CF',
    'Welsh Green Party' => '#02A95B',
    'Welsh Liberal Democrats' => '#FF6400',
    'Welsh Labour and Co‑operative Party' => '#E4003B',
    'Welsh Labour and Co-operative Party' => '#E4003B',
    'Welsh Labour' => '#E4003B',
    'Welsh Conservative Party' => '#0087DC'
  }

  CSS_CLASSES = {
    'Plaid Cymru' => 'plaid-cymru',
    'Reform UK' => 'reform-uk',
    'Reform UK Wales' => 'reform-uk',
    'Welsh Green Party' => 'green',
    'Welsh Liberal Democrats' => 'liberal-democrats',
    'Welsh Labour and Co‑operative Party' => 'labour-and-co-op',
    'Welsh Labour and Co-operative Party' => 'labour-and-co-op',
    'Welsh Labour' => 'labour',
    'Welsh Conservative Party' => 'conservative'
  }

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

  def url
    I18n.locale == :"cy-GB" ? url_cy : url_en
  end

  def colour
    PARTY_COLOURS.fetch(party_en, '#DCDCDC')
  end

  def css_class
    CSS_CLASSES.fetch(party_en, '')
  end

  private

  def url_en
    URL_EN % { slug: name_en.parameterize }
  end

  def url_cy
    URL_CY % { slug: name_cy.parameterize }
  end
end
