namespace :errors do
  desc "Precompile error pages into /public"
  task :precompile => :environment do
    require 'base64'

    controller_class = Class.new(ActionController::Base) do
      def url_options
        Site.constraints_for_public
      end
    end

    context_class = Class.new(ActionView::Base.with_empty_template_cache) do
      include Rails.application.routes.url_helpers

      def data_uri(path)
        if path =~ /svg\z/
          "data:image/svg+xml;base64,#{Base64.strict_encode64(asset_data(path))}"
        else
          "data:image/png;base64,#{Base64.strict_encode64(asset_data(path))}"
        end
      end

      def asset_data(path)
        File.read(Rails.root.join('app', 'assets', 'images', path))
      end

      def home_page?
        false
      end

      def holding_page?
        false
      end
    end

    lookup_context = ActionView::LookupContext.new('app/views')

    %w[400 403 404 406 410 422 500 503].each do |status|
      context = context_class.new(lookup_context, { status: status }, controller_class.new)
      File.open(Rails.public_path.join("#{status}.html"), 'wb') do |f|
        f.write context.render(template: "errors/#{status}", layout: 'errors/layout')
      end
    end

    context = context_class.new(lookup_context, {}, controller_class.new)
    File.open(Rails.public_path.join("error.css"), 'wb') do |f|
      f.write context.render(template: "errors/error", layout: false)
    end
  end

  task :clobber => :environment do
    %w[400 403 404 406 410 422 500 503].each do |status|
      html_file = Rails.public_path.join("#{status}.html")
      File.unlink(html_file) if File.exist?(html_file)
    end

    css_file = Rails.public_path.join("error.css")
    File.unlink(css_file) if File.exist?(css_file)
  end
end

task 'assets:precompile' => 'errors:precompile'
task 'assets:clobber' => 'errors:clobber'
