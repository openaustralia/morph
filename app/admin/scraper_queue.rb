# typed: false
# frozen_string_literal: true

ActiveAdmin.register_page "Scraper Queue" do
  content do
    para "Jobs in the #{link_to 'Sidekiq', admin_sidekiq_path} scraper queue.".html_safe

    workers = Sidekiq::Workers.new
    active_runs = workers.collect do |_process_id, _thread_id, work|
      next if work["queue"] != "scraper"

      {
        run: Run.find(work["payload"]["args"].first),
        enqueued_at: Time.zone.at(work["payload"]["enqueued_at"]),
        run_at: Time.zone.at(work["run_at"])
      }
    end.compact
    active_runs.sort! { |a, b| b[:enqueued_at] <=> a[:enqueued_at] }

    h1 "#{active_runs.count} busy"
    para "Scrapers with a busy Sidekiq job."
    unless active_runs.empty?
      table do
        thead do
          tr do
            th "Run ID"
            th "Scraper name"
            th "Enqueued"
            th "Started"
          end
        end

        tbody do
          active_runs.each do |record|
            scraper = record[:run].scraper
            tr do
              td link_to record[:run].id, admin_run_path(record[:run])
              td link_to scraper.full_name, scraper
              td "#{time_ago_in_words(record[:enqueued_at])} ago"
              td "#{time_ago_in_words(record[:run_at])} ago"
            end
          end
        end
      end
    end

    enqueued_runs = Sidekiq::Queue["scraper"].collect do |j|
      {
        run: Run.find(j.item["args"].first),
        enqueued_at: Time.zone.at(j.item["enqueued_at"])
      }
    end
    enqueued_runs.sort! { |a, b| b[:enqueued_at] <=> a[:enqueued_at] }

    h1 "#{Sidekiq::Queue['scraper'].size} enqueued"
    para "Scrapers with an enqueued Sidekiq job."
    unless enqueued_runs.empty?
      table do
        thead do
          tr do
            th "Run ID"
            th "Scraper name"
            th "Enqueued"
          end
        end

        tbody do
          enqueued_runs.each do |record|
            scraper = record[:run].scraper
            tr do
              td link_to record[:run].id, admin_run_path(record[:run])
              td link_to scraper.full_name, scraper
              td "#{time_ago_in_words(record[:enqueued_at])} ago"
            end
          end
        end
      end
    end
  end
end
