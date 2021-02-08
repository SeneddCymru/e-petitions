module Notifications
  class Event
    TYPES = {
      "Delivery"          => "delivery",
      "Bounce"            => "bounce",
      "Complaint"         => "complaint",
      "Reject"            => "reject",
      "Rendering Failure" => "failure"
    }

    class << self
      def parse(message)
        json = JSON.parse(message)
        data = JSON.parse(json.fetch("Message"))

        new(data)
      end
    end

    attr_reader :data, :mail

    def initialize(data)
      @data = data
      @mail = @data.fetch("mail")
    end

    def message_id
      mail.fetch("messageId")
    end

    def timestamp
      @timestamp ||= mail.fetch("timestamp").in_time_zone
    end

    def type
      @type ||= TYPES[data.fetch("eventType")]
    end

    def payload
      @payload ||= data.fetch(type)
    end
  end
end
