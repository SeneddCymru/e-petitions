require 'aws-sdk-sesv2'

module Notifications
  class Notification < ActiveRecord::Base
    enum status: {
      created:    0,
      sending:    1,
      delivered:  2,
      bounced:    3,
      rejected:   4,
      complained: 5,
      failed:     6
    }

    UUID = /\A[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}\z/

    VALID_KEYS = %i[
      email_address
      template_id
      reference
      personalisation
    ]

    validates :to, presence: true, email: true
    validates :template_id, presence: true, format: { with: UUID }
    validates :reference, presence: true, length: { maximum: 100 }

    before_validation do
      self.personalisation ||= {}
    end

    before_save do
      if failure.present?
        self.status = :failed
      elsif reject.present?
        self.status = :rejected
      elsif complaint.present?
        self.status = :complained
      elsif bounce.present?
        self.status = :bounced
      elsif delivery.present?
        self.status = :delivered
      else
        self.status = :sending
      end
    end

    alias_attribute :email_address, :to

    store_accessor :events, :delivery
    store_accessor :events, :bounce
    store_accessor :events, :complaint
    store_accessor :events, :reject
    store_accessor :events, :failure

    class << self
      def send!(options)
        options.assert_valid_keys(*VALID_KEYS)

        transaction do
          notification = create!(options)

          client = Aws::SESV2::Client.new
          response = client.send_email(notification.payload)

          if response.successful?
            notification.update!(message_id: response.message_id)
          end
        end
      end

      def process!(event)
        notification = find_by!(message_id: event.message_id)
        notification.update!(event.type => event.payload)
      end
    end

    def payload
      {
        from_email_address: Site.email_from,
        destination: { to_addresses: [to] },
        configuration_set_name: configuration_set,
        content: { template: {
          template_name: template_id_for_ses,
          template_data: personalisation.to_json
        }},
        email_tags: [
          { name: "reference", value: reference },
          { name: "notification_id", value: id }
        ]
      }
    end

    def resend!
      transaction do
        client = Aws::SESV2::Client.new
        response = client.send_email(payload)

        if response.successful?
          update!(message_id: response.message_id, events: {})
        end
      end
    end

    private

    def configuration_set
      ENV.fetch("EMAIL_CONFIG")
    rescue KeyError => e
      raise Client::NotConfiguredError, "Email configuration set not found"
    end

    def template_id_for_ses
      "%s-%s" % [Site.env, template_id]
    end
  end
end
