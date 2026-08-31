class Contact < ActiveRecord::Base
  belongs_to :signature

  validates :signature, presence: true
  validates :address, presence: true, length: { maximum: 500 }
  validates :phone_number, presence: true, length: { maximum: 31 }

  def address=(value)
    super(value.to_s.strip)
  end

  def phone_number=(value)
    super(value.to_s.tr('^1234567890+./ ', ''))
  end

  def anonymized?
    anonymized_at?
  end

  def anonymize!(timestamp)
    return if anonymized?

    with_lock do
      # Set the address to the address of the Senedd and the
      # phone number to an Ofcom-approved fake number for Cardiff.
      self.address = "Cardiff Bay, Cardiff"
      self.phone_number = "029 2018 1234"
      self.anonymized_at = timestamp

      save!
    end
  end
end
