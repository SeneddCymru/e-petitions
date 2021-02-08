class NotifySponsorThatPetitionIsPublishedEmailJob < NotifyJob
  include DateTimeHelper
  self.template = :notify_sponsor_that_petition_is_published

  def template_id(signature)
    if !signature.petition.collect_signatures?
      self.template = :notify_sponsor_that_petition_is_published_without_signatures
    end
    super
  end

  def personalisation(signature, petition)
    {
      sponsor: signature.name,
      action_en:  petition.action_en, action_gd: petition.action_gd,
      closing_date: short_date_format(petition.closed_at),
      url_en:  petition_en_url(petition), url_gd:  petition_gd_url(petition),
      petition_website_url_en: home_en_url, petition_website_url_gd: home_gd_url
    }
  end
end
