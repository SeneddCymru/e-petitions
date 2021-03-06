class NotifyCreatorThatPetitionWasRejectedEmailJob < NotifyJob
  self.template = :notify_creator_that_petition_was_rejected

  def personalisation(signature, petition, rejection)
    I18n.with_locale(petition.locale) do
      if insufficient_petition?
        {
          creator: signature.name,
          action_en: petition.action_en, action_cy: petition.action_cy,
          content_en: rejection.content_en, content_cy: rejection.content_cy,
          url_en: petition_en_url(petition), url_cy: petition_cy_url(petition),
          standards_url_en: help_en_url(anchor: "standards"),
          standards_url_cy: help_cy_url(anchor: "standards"),
          new_petition_url_en: check_petitions_en_url,
          new_petition_url_cy: check_petitions_cy_url
        }
      else
        {
          creator: signature.name, action: petition.action,
          content_en: rejection.content_en, content_cy: rejection.content_cy,
          url_en: petition_en_url(petition), url_cy: petition_cy_url(petition),
          standards_url_en: help_en_url(anchor: "standards"),
          standards_url_cy: help_cy_url(anchor: "standards"),
          new_petition_url_en: check_petitions_en_url,
          new_petition_url_cy: check_petitions_cy_url
        }
      end
    end
  end

  def template
    if hidden_petition?
      :"#{super}_hidden"
    elsif insufficient_petition?
      :"#{super}_insufficient"
    else
      super
    end
  end

  private

  def hidden_petition?
    arguments.first.petition.hidden?
  end

  def insufficient_petition?
    arguments.last.code == "insufficient"
  end
end
