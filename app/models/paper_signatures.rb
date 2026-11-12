class PaperSignatures
  include ActiveModel::Model
  include ActiveModel::Attributes

  LOCATION_CODES = %w[GB-WLS GB-ENG GB-SCT GB-NIR]
  MAXIMUM_SIGNATURES = 10_000

  attr_reader :petition, :ip_address

  attribute :location_code, :string, default: "GB-WLS"
  attribute :signature_count, :integer

  validates :location_code, inclusion: { in: LOCATION_CODES }
  validates :signature_count, presence: true

  validates :signature_count, numericality: {
    only_integer: true, greater_than: 0, less_than_or_equal_to: MAXIMUM_SIGNATURES
  }, allow_blank: true

  def initialize(petition, ip_address, attributes = {})
    @petition = petition
    @ip_address = ip_address
    super(attributes)
  end

  # Used by the numericality validator to check the
  # value entered rather than the integer cast value
  def signature_count_before_type_cast
    @attributes["signature_count"].value_before_type_cast
  end

  def save
    return false unless valid?

    job = AddPaperSignaturesJob.perform_later(petition, location_code, signature_count, ip_address)
    job && job.successfully_enqueued?
  end
end
