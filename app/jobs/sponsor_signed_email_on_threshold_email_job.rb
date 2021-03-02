class SponsorSignedEmailOnThresholdEmailJob < NotifyJob
  self.template = :sponsor_signed_email_on_threshold

  def perform(creator, sponsor)
    if sponsor.validated?
      super
    end
  end

  def personalisation(creator, petition, sponsor)
    I18n.with_locale(petition.locale) do
      {
        sponsor: sponsor.name,
        creator: creator.name,
        action:  petition.action,
        url_en:  help_en_url(anchor: 'rules'),
        url_gd:  help_gd_url(anchor: 'rules')
      }
    end
  end

  def template
    if christmas_period?
      :"#{super}_christmas"
    elsif easter_period?
      :"#{super}_easter"
    else
      super
    end
  end
end
