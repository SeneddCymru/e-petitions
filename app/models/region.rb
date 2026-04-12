class Region < ActiveRecord::Base
  include Translatable

  translate :name

  has_many :constituencies
  has_many :members

  default_scope { preload(:members).order(:id) }

  class << self
    def current
      where(end_date: nil)
    end

    def for(dates)
      if dates.end
        where(start_date: ..dates.begin, end_date: dates.end..)
      else
        where(start_date: ..dates.begin, end_date: nil)
      end
    end
  end
end
