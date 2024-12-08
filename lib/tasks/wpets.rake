namespace :wpets do
  desc "Add sysadmin user"
  task :add_sysadmin_user => :environment do
    if AdminUser.find_by(email: 'admin@example.com').nil?
       admin = AdminUser.new(:first_name => 'Cool', :last_name => 'Admin', :email => 'admin@example.com')
       admin.role = 'sysadmin'
       admin.password = admin.password_confirmation = 'Letmein1!'
       admin.save!
     end
  end

  namespace :jobs do
    desc "Unlock all delayed jobs (to be used after a restart)"
    task :unlock_all => :environment do
      Delayed::Job.update_all("locked_by = NULL, locked_at = NULL")
    end
  end

  namespace :site do
    desc "Enable the website"
    task :enable => :environment do
      Site.instance.update! enabled: true
    end

    desc "Disable the website"
    task :disable => :environment do
      Site.instance.update! enabled: false
    end

    desc "Protect the website"
    task :protect => :environment do
      Site.instance.update! protected: true, username: ENV.fetch('SITE_USERNAME'), password: ENV.fetch('SITE_PASSWORD')
    end

    desc "Unprotect the website"
    task :unprotect => :environment do
      Site.instance.update! protected: false
    end

    desc "Start the signature count updater if it's not running"
    task :signature_counts => :environment do
      Task.run("wpets:site:signature_counts", 10.minutes) do
        break unless Site.update_signature_counts

        unless Site.signature_count_updated_at > 15.minutes.ago
          UpdateSignatureCountsJob.perform_later
        end
      end
    end

    desc "Track trending domains"
    task :trending_domains => :environment do
      Task.run("wpets:site:trending_domains", 30.minutes) do
        TrendingDomainsByPetitionJob.perform_later
      end
    end

    desc "Track trending IP addresses"
    task :trending_ips => :environment do
      Task.run("wpets:site:trending_ips", 30.minutes) do
        TrendingIpsByPetitionJob.perform_later
      end
    end
  end
end
