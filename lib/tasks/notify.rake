require 'aws-sdk-sesv2'

namespace :notify do
  task create_templates: :environment do
    templates = Rails.root.join("spec", "fixtures", "notify", "*")
    client = Aws::SESV2::Client.new

    Dir[templates].each do |file|
      Notifications::Template.create!(YAML.load_file(file))

      sleep(0.5) # Otherwise we'll trigger a TooManyRequestsException
    end
  end

  task update_templates: :environment do
    templates = Rails.root.join("spec", "fixtures", "notify", "*")
    client = Aws::SESV2::Client.new

    Dir[templates].each do |file|
      yaml = YAML.load_file(file)

      template = Notifications::Template.find(yaml["id"])
      template.update!(subject: yaml["subject"], body: yaml["body"])

      sleep(0.5) # Otherwise we'll trigger a TooManyRequestsException
    end
  end

  task delete_templates: :environment do
    Notifications::Template.find_each do |template|
      template.destroy

      sleep(0.5) # Otherwise we'll trigger a TooManyRequestsException
    end
  end
end
