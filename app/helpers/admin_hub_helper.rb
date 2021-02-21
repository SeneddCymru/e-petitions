module AdminHubHelper
  def petition_total_count
    @petition_total_count ||= Petition.all.count
  end

  def in_moderation_count
    @in_moderation_count ||= Petition.in_moderation.count
  end

  def recently_in_moderation_count
    @recently_in_moderation_count ||= Petition.recently_in_moderation.count
  end

  def recently_in_moderation_untagged_count
    @recently_in_moderation_untagged_count ||= Petition.untagged.recently_in_moderation.count
  end

  def nearly_overdue_in_moderation_untagged_count
    @nearly_overdue_in_moderation_untagged_count ||= Petition.untagged.nearly_overdue_in_moderation.count
  end

  def nearly_overdue_in_moderation_count
    @nearly_overdue_in_moderation_count ||= Petition.nearly_overdue_in_moderation.count
  end

  def overdue_in_moderation_count
    @overdue_in_moderation_count ||= Petition.overdue_in_moderation.count
  end

  def overdue_in_moderation_untagged_count
    @overdue_in_moderation_untagged_count ||= Petition.untagged.overdue_in_moderation.count
  end

  def tagged_in_moderation_count
    @tagged_in_moderation_count ||= Petition.tagged_in_moderation.count
  end

  def untagged_in_moderation_count
    @untagged_in_moderation_count ||= Petition.untagged_in_moderation.count
  end

  def summary_class_name_for_in_moderation
    if overdue_in_moderation_count > 0
      "queue-danger"
    elsif nearly_overdue_in_moderation_count > 0
      "queue-caution"
    else
      "queue-stable"
    end
  end

  class ActionCountsDecorator
    delegate :each, :empty?, to: :counts

    private

    def counts
      @counts ||= generate_counts
    end

    def generate_counts
      [].tap do |counts|
        counts << [:referred, Petition.facet_count(:referred)]

        if Site.disable_thresholds_and_debates?
          counts << [:completed, Petition.facet_count(:completed)]
        else
          counts << [:in_debate_queue, Petition.facet_count(:in_debate_queue)]
        end
      end
    end
  end

  def action_counts(&block)
    yield ActionCountsDecorator.new
  end

  def action_count(key, count)
    t(:"#{key}_html", scope: :"petitions.action_counts", formatted_count: number_with_delimiter(count))
  end
end
