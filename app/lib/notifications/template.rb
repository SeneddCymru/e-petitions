require 'aws-sdk-sesv2'
require 'textacular/searchable'

module Notifications
  class Template < ActiveRecord::Base
    extend Searchable(:name, :subject)
    include Browseable

    self.default_page_size = 10

    PLACEHOLDER = /\(\(([a-zA-Z][_a-zA-Z0-9]*)\)\)/

    validates :name, :subject, :body, presence: true
    validates :name, uniqueness: true
    validates :name, :subject, length: { maximum: 100 }
    validates :body, length: { maximum: 10000 }

    after_save :sync_template_to_ses
    after_destroy :delete_template_from_ses

    facet :all, -> { by_name }

    class << self
      def by_name
        order(name: :asc)
      end
    end

    def html
      view.render(template: "layouts/notification", formats: [:html], layout: false)
    end

    def text
      view.render(template: "layouts/notification", formats: [:text], layout: false)
    end

    def to_partial_path
      "admin/templates/template"
    end

    private

    def view
      @view ||= TemplateView.new(assigns)
    end

    def subject_for_ses
      @subject_for_ses ||= subject.gsub(PLACEHOLDER) { "{{#{$1}}}" }
    end

    def assigns
      { subject: subject_for_ses, body: body }
    end

    def client
      @client ||= Aws::SESV2::Client.new
    end

    def sync_template_to_ses
      if template_exists_in_ses?
        client.update_email_template(payload_for_ses)
      else
        client.create_email_template(payload_for_ses)
      end
    end

    def template_id_for_ses
      "%s-%s" % [Site.env, id]
    end

    def delete_template_from_ses
      client.delete_email_template(template_name: template_id_for_ses)
    rescue Aws::SESV2::Errors::NotFoundException
      true
    end

    def template_exists_in_ses?
      client.get_email_template(template_name: template_id_for_ses)
    rescue Aws::SESV2::Errors::NotFoundException
      false
    end

    def payload_for_ses
      {
        template_name: template_id_for_ses,
        template_content: {
          subject: subject_for_ses,
          text: text, html: html
        }
      }
    end
  end
end