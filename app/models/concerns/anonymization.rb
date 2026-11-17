module Anonymization
  extend ActiveSupport::Concern

  module ClassMethods
    def anonymize_petitions!(time = Time.current)
      in_need_of_anonymizing(12.months.ago(time)).find_each do |petition|
        petition.anonymize!(time) unless petition.do_not_anonymize?
      end
    end

    def not_anonymized
      where(anonymized_at: nil)
    end

    def completed_before(time)
      where(state: self::COMPLETED_STATE).where(arel_table[:completed_at].lt(time))
    end

    def rejected_before(time)
      where(state: self::REJECTED_STATES).where(arel_table[:rejected_at].lt(time))
    end

    def in_need_of_anonymizing(time = 12.months.ago)
      not_anonymized.and(completed_before(time).or(rejected_before(time)))
    end
  end

  def anonymize!(time = Time.current)
    AnonymizePetitionJob.perform_later(self, time.iso8601)
  end

  def anonymized?
    anonymized_at?
  end
end
