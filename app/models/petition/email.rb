class Petition < ActiveRecord::Base
  class Email < ActiveRecord::Base
    include Translatable

    belongs_to :petition, touch: true

    translate :subject, :body

    validates :petition, presence: true
    validates :subject_en, presence: true, length: { maximum: 100 }
    validates :body_en, presence: true, length: { maximum: 5000 }

    with_options unless: :gaelic_disabled? do
      validates :subject_gd, presence: true, length: { maximum: 100 }
      validates :body_gd, presence: true, length: { maximum: 5000 }
    end
  end
end
