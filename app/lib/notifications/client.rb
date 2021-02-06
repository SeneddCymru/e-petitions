require 'aws-sdk-sesv2'

module Notifications
  class Client
    class RequestError < StandardError; end
    class ClientError < RequestError; end
    class BadRequestError < ClientError; end
    class AuthError < ClientError; end
    class NotFoundError < ClientError; end
    class RateLimitError < ClientError; end
    class LimitExceededError < ClientError; end
    class ServerError < RequestError; end
    class NotConfiguredError < RuntimeError; end

    ERROR_MAPPING = {
      Aws::SESV2::Errors::AccountSuspendedException => ClientError,
      Aws::SESV2::Errors::AlreadyExistsException => ClientError,
      Aws::SESV2::Errors::BadRequestException => BadRequestError,
      Aws::SESV2::Errors::ConcurrentModificationException => ClientError,
      Aws::SESV2::Errors::ConflictException => ClientError,
      Aws::SESV2::Errors::InvalidNextTokenException => AuthError,
      Aws::SESV2::Errors::LimitExceededException => LimitExceededError,
      Aws::SESV2::Errors::MailFromDomainNotVerifiedException => AuthError,
      Aws::SESV2::Errors::MessageRejected => ClientError,
      Aws::SESV2::Errors::NotFoundException => NotFoundError,
      Aws::SESV2::Errors::SendingPausedException => ClientError,
      Aws::SESV2::Errors::TooManyRequestsException => RateLimitError
    }


    def send_email(options)
      Notification.send!(options)

    rescue Aws::SESV2::Errors::ServiceError => e
      response = e.context.http_response

      if ERROR_MAPPING.key?(e.class)
        raise ERROR_MAPPING[e.class], e.message
      elsif response.status_code.in?(400..499)
        raise ClientError, e.message
      elsif response.status_code.in?(500..599)
        raise ServerError, e.message
      end
    rescue Seahorse::Client::NetworkingError => e
      raise ServerError, e.message
    end
  end
end
