require 'csv'

class PetitionCSVPresenter
  include CsvHelper
  include DateTimeHelper
  include Rails.application.routes.url_helpers

  def self.fields
    urls + attributes + timestamps + [:notes]
  end

  def initialize(petition)
    @petition = petition
  end

  def to_csv
    CSV::Row.new(self.class.fields, values).to_s
  end

  attr_reader :petition

  private

  def self.urls
    [:public_url, :admin_url]
  end

  def self.attributes
    [:pp_number, :pe_number,
      :action, :background, :previous_action, :additional_details, :state,
      :creator_name, :creator_email, :signature_count, :rejection_code, :rejection_details,
      :debate_date, :debate_transcript_url, :debate_video_url, :debate_pack_url, :debate_overview
    ]
  end

  def self.timestamps
    [
      :created_at, :updated_at, :open_at, :closed_at, :scheduled_debate_date,
      :referral_threshold_reached_at, :debate_threshold_reached_at, :rejected_at,
      :debate_outcome_at, :moderation_threshold_reached_at, :completed_at
    ]
  end

  def values
    self.class.fields.map {|field| send field }
  end

  def public_url
    petition_url @petition
  end

  def admin_url
    admin_petition_url @petition
  end

  def notes
    petition.note.details if petition.note
  end

  attributes.each do |attribute|
    define_method attribute do
      if attribute == :pp_number
        pp_number = ('PP%04d' % petition.send("id"))
        csv_escape pp_number
      elsif attribute == :pe_number
        unless petition.send("pe_number_id").nil?
          pe_number = ('PE%04d' % petition.send("pe_number_id"))
          csv_escape pe_number
        end
      else
        csv_escape petition.send attribute
      end
    end
  end

  timestamps.each do |timestamp|
    define_method timestamp do
      api_date_format petition.send timestamp
    end
  end
end
