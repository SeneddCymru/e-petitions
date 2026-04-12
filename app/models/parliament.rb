module Parliament
  Session = Struct.new(:name, :start_date, :end_date) do
    def constituencies
      @constituencies ||= Constituency.for(dates)
    end

    def cover?(date)
      (start_date..end_date).cover?(date)
    end

    def current?(today = Date.current)
      cover?(today)
    end

    def dates
      start_date..end_date
    end

    def regions
      @regions ||= Region.for(dates)
    end

    alias_method :to_param, :name
    alias_method :to_s, :name
  end

  SESSIONS = [
    Session.new('2007-11', Date.civil(2007, 5, 3), Date.civil(2011, 5, 4)),
    Session.new('2011-16', Date.civil(2011, 5, 5), Date.civil(2016, 5, 4)),
    Session.new('2016-21', Date.civil(2016, 5, 5), Date.civil(2021, 5, 5)),
    Session.new('2021-26', Date.civil(2021, 5, 6), Date.civil(2026, 5, 6)),
    Session.new('2026-31', Date.civil(2026, 5, 7), nil)
  ]

  class << self
    def at(date)
      SESSIONS.detect { |session| session.cover?(date) }
    end

    def current
      SESSIONS.last
    end

    def find(name)
      SESSIONS.detect { |session| session.name == name }
    end

    def find!(name)
      find(name) || (raise ActiveRecord::RecordNotFound, "Unable to find parliament session for #{name.inspect}")
    end
  end
end
