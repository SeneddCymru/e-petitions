class EmailConfirmationForCreatorEmailJob < NotifyJob
  self.template = :email_confirmation_for_creator

  include RateLimiting

  def personalisation(signature, petition)
    {
      action_en:  petition.action_en, action_gd: petition.action_gd,
      url_en:  verify_petitioner_en_url(signature, token: signature.perishable_token),
      url_gd:  verify_petitioner_gd_url(signature, token: signature.perishable_token),
      moderation_info_url_en: help_en_url(anchor: 'standards'),
      moderation_info_url_gd: help_gd_url(anchor: 'standards'),
    }
  end
end
