require 'postcode_sanitizer'

class Constituency < ActiveRecord::Base
  include Translatable

  POSTCODE = /\A([A-Z]{1,2}[0-9][0-9A-Z]?)([0-9]|[0-9][A-BD-HJLNP-UW-Z]{2})?\z/i

  translate :name

  belongs_to :region
  has_one :member
  has_many :postcodes

  has_many :signatures
  has_many :petitions, through: :signatures

  delegate :name, :url, to: :member, prefix: true

  default_scope { preload(:member, :region).order(:id) }

  class << self
    def find_by_postcode(query)
      sanitized_postcode = sanitize_postcode(query)

      if valid_postcode?(sanitized_postcode)
        joins(:postcodes).where(postcode.eq(sanitized_postcode)).take
      end
    end

    private

    def postcode
      Postcode.arel_table[:id]
    end

    def sanitize_postcode(postcode)
      PostcodeSanitizer.call(postcode)
    end

    def valid_postcode?(postcode)
      postcode.match?(POSTCODE)
    end
  end

  def slug
    name.parameterize
  end
end
