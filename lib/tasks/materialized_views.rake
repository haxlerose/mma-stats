# frozen_string_literal: true

namespace :materialized_views do
  desc "Refresh all materialized views"
  task refresh: :environment do
    puts "Refreshing fight_durations materialized view..."
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW CONCURRENTLY fight_durations"
    )
    puts "Done!"
  end

  desc "Refresh fight_durations materialized view"
  task refresh_fight_durations: :environment do
    puts "Refreshing fight_durations materialized view..."
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW CONCURRENTLY fight_durations"
    )
    puts "Done!"
  end
end

# Hook into db:migrate to refresh materialized views
Rake::Task["db:migrate"].enhance do
  if ActiveRecord::Base.connection.table_exists?("fight_durations")
    Rake::Task["materialized_views:refresh"].invoke
  end
end
