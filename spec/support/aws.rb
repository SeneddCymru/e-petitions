require 'aws-sdk-sesv2'

RSpec.configure do |config|
  config.before(:suite) do
    # The AWS SDK client will automatically retry requests but that
    # just makes our tests run slower so we need to turn it off.
    Aws.config.update(max_attempts: 0, retry_limit: 0)

    # The AWS SDK client doesn't set the Content-Type header by
    # default so we have to add a Seahorse plugin to do it for
    # us so that we can use partial request matching with WebMock.
    plugin = Class.new(Seahorse::Client::Plugin) do
      content_type = Class.new(Seahorse::Client::Handler) do
        def call(context)
          context.http_request.headers['Content-Type'] = 'application/json'
          @handler.call(context)
        end
      end

      handler(content_type, step: :sign, priority: 0)
    end

    Aws::SESV2::Client.add_plugin(plugin)
  end
end
