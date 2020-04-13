class NotifySponsorThatPetitionWasRejectedEmailJob < NotifyJob
  self.template = :notify_sponsor_that_petition_was_rejected

  def personalisation(signature, petition, rejection)
    I18n.with_locale(petition.locale) do
      {
        sponsor: signature.name, action: petition.action,
        content_en: rejection.content_en, content_cy: rejection.content_cy,
        url_en: petition_en_url(petition), url_cy: petition_cy_url(petition),
        standards_url_en: help_en_url(anchor: "standards"),
        standards_url_cy: help_cy_url(anchor: "standards")
      }
    end
  end

  def template
    if hidden_petition?
      :"#{super}_hidden"
    else
      super
    end
  end

  private

  def hidden_petition?
    arguments.first.petition.hidden?
  end
end
