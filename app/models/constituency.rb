require 'postcode_sanitizer'

class Constituency < ActiveRecord::Base
  include Translatable

  POSTCODE = /\A([A-Z]{1,2}[0-9][0-9A-Z]?)([0-9]|[0-9][A-BD-HJLNP-UW-Z]{2})?\z/i

  translate :name

  belongs_to :region, optional: true
  has_many :members
  has_many :postcodes

  has_many :signatures
  has_many :petitions, through: :signatures

  default_scope { preload(:members, :region).order(:id) }

  class << self
    def current
      where(end_date: nil)
    end

    def find_by_postcode(query)
      sanitized_postcode = sanitize_postcode(query)

      if valid_postcode?(sanitized_postcode)
        joins(:postcodes).where(postcode.eq(sanitized_postcode)).take
      end
    end

    def for(dates)
      if dates.end
        where(start_date: ..dates.begin, end_date: dates.end..)
      else
        where(start_date: ..dates.begin, end_date: nil)
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
