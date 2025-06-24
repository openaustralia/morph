class AddForeignKeyConstraints < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :api_queries, :scrapers
    add_foreign_key :connection_logs, :runs
    add_foreign_key :connection_logs, :domains
    add_foreign_key :contributions, :scrapers
    add_foreign_key :log_lines, :runs
    add_foreign_key :metrics, :runs
    add_foreign_key :runs, :scrapers
    add_foreign_key :scrapers, :create_scraper_progresses
    add_foreign_key :variables, :scrapers
    add_foreign_key :webhook_deliveries, :webhooks
    add_foreign_key :webhook_deliveries, :runs
    add_foreign_key :webhooks, :scrapers

    # We haven't added any of the constraints that involve owners because
    # the migration failed in production. There is some more investigating to do.

    # We can't add a simple constraint for watch_id on the alerts table because
    # it's polymorphic
    #add_foreign_key :alerts, :owners, column: "user_id"
    #add_foreign_key :api_queries, :owners
    #add_foreign_key :contributions, :owners, column: "user_id"
    #add_foreign_key :organizations_users, :owners, column: "organization_id"
    #add_foreign_key :organizations_users, :owners, column: "user_id"
    #add_foreign_key :runs, :owners
    #add_foreign_key :scrapers, :owners
    #add_foreign_key :scrapers, :owners, column: "forked_by_id"
  end
end
