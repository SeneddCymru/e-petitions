module Notifications
  class Event < Hash
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

    def initialize(data)
      super()
      update(data)
    end

    def message_id
      @message_id ||= dig("mail", "messageId")
    end

    def timestamp
      @timestamp ||= dig("mail", "timestamp").in_time_zone
    end

    def type
      @type ||= TYPES[fetch("eventType")]
    end

    def payload
      @payload ||= fetch(type)
    end
  end
end
