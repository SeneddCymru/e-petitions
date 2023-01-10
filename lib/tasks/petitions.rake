namespace :spets do
  namespace :petitions do
    desc "Add a task to the queue to validate petition counts"
    task :count => :environment do
      Task.run("spets:petitions:count") do
        PetitionCountJob.perform_later
      end
    end

    desc "Add a task to the queue to mark petitions as debated at midnight"
    task :debated => :environment do
      Task.run("spets:petitions:debated") do
        date = Date.tomorrow
        DebatedPetitionsJob.set(wait_until: date.beginning_of_day).perform_later(date.iso8601)
      end
    end

    desc "Add a task to the queue to update petition statistics"
    task :update_statistics => :environment do
      Task.run("spets:petitions:update_statistics", 12.hours) do
        EnqueuePetitionStatisticsUpdatesJob.perform_later(24.hours.ago.iso8601)
      end
    end
  end
end
