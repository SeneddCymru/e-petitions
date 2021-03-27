class NotifyJob < ApplicationJob
  include Rails.application.routes.url_helpers

  class_attribute :template
  queue_as :high_priority

  before_perform :set_appsignal_namespace

  DELAY_FOR_24_HOURS = [
    Notifications::Client::BadRequestError,
    Notifications::Client::AuthError,
    Notifications::Client::NotFoundError,
    Notifications::Client::ClientError,
    Notifications::Client::RequestError
  ]

  DELAY_FOR_1_HOUR = [
    Notifications::Client::ServerError,
    Timeout::Error,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    EOFError,
    SocketError
  ]

  rescue_from Notifications::Client::NotConfiguredError do |exception|
    log_exception(exception)
  end

  # Unexpected error so give us a day to sort things out.
  # If we sort it out before then we can always requeue manually.
  rescue_from *DELAY_FOR_24_HOURS do |exception|
    reschedule_job 24.hours.from_now
    Appsignal.send_exception(exception) { |t| t.namespace("email") }
  end

  # It's likely that the GOV.UK Notify platform is having problems so
  # delay for an hour to allow them to fix the problem or demand to fall.
  # Don't notify Appsignal because it's likely fix itself.
  rescue_from *DELAY_FOR_1_HOUR do |exception|
    reschedule_job 1.hour.from_now
    log_exception(exception)
  end

  # No need to notify Appsignal about this errors as it self heals.
  # If we hit the rate limit just delay for five minutes.
  rescue_from Notifications::Client::RateLimitError do |exception|
    reschedule_job 5.minutes.from_now
  end

  # No need to notify Appsignal about this errors as it self heals.
  # If we hit the daily limit delay until the start of the next day.
  rescue_from Notifications::Client::LimitExceededError do |exception|
    reschedule_job Date.tomorrow.beginning_of_day
  end

  # Likely something got deleted so just flag in Appsignal and drop the job.
  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception(exception) { |t| t.namespace("email") }
  end

  def perform(signature, *args)
    client.send_email(
      email_address: signature.email,
      template_id: template_id(signature),
      reference: reference(signature),
      personalisation: personalise(signature, *args)
    )
  end

  private

  def client
    @client ||= Notifications::Client.new
  end

  def template_id(signature)
    I18n.t(template, scope: :"notify.templates", locale: signature.locale)
  end

  def reference(signature)
    signature.uuid
  end

  def personalise(signature, *args)
    I18n.with_locale(signature.locale) do
      personalisation(signature, signature.petition, *args).merge(thresholds)
    end
  end

  def thresholds
    {
      moderation_threshold: Site.formatted_threshold_for_moderation,
      referral_threshold: Site.formatted_threshold_for_referral,
      debate_threshold: Site.formatted_threshold_for_debate
    }
  end

  def personalisation(signature, petition)
    {} # subclasses need to override this method
  end

  def moderation_delay?
    @moderation_delay ||= Petition.in_moderation.count >= Site.threshold_for_moderation_delay
  end

  def easter_period?(today = Date.current)
    Holiday.easter?(today)
  end

  def christmas_period?(today = Date.current)
    Holiday.christmas?(today)
  end

  def log_exception(exception)
    logger.info(log_message(exception))
  end

  def log_message(exception)
    "#{exception.class.name} while sending email for #{self.class.name}"
  end

  def set_appsignal_namespace
    Appsignal.set_namespace("email")
  end

  def reschedule_job(time = 1.hour.from_now)
    self.class.set(wait_until: time).perform_later(*arguments)
  end
end
