# typed: strict
# frozen_string_literal: true

# Run API used by the morph command-line client
class ApiController < ApplicationController
  extend T::Sig

  include ActionController::Live

  # The run_remote method will be secured with a key so shouldn't need csrf
  # token authentication
  skip_before_action :verify_authenticity_token, only: [:run_remote]
  before_action :authenticate_api_key, only: :run_remote
  before_action :can_run, only: :run_remote

  # Receive code from a remote client, run it and return the result.
  # This will be a long running request
  # TODO: Document this API
  sig { void }
  def run_remote
    params_code = T.cast(params[:code], ActionDispatch::Http::UploadedFile)
    response.headers["Content-Type"] = "text/event-stream"
    run = Run.create(queued_at: Time.zone.now, auto: false, owner: current_user)
    # TODO: Shouldn't need to untar here because it just gets retarred
    Archive::Tar::Minitar.unpack(params_code.tempfile, run.repo_path)
    runner = Morph::Runner.new(run)
    runner.go { |_timestamp, s, text| stream_message(s, text) }
  ensure
    # Cleanup run
    response.stream.close
    # Don't want to leave any containers hanging around
    container = runner&.container_for_run
    if container
      container.kill
      container.delete
    end
    if run
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
    end
  end

  sig { void }
  def data
    begin
      scraper = T.let(Scraper.friendly.find(params[:id]), Scraper)
    rescue ActiveRecord::RecordNotFound
      render_error "can't find scraper #{params[:id]}", 404
      return
    end

    @scraper = T.let(scraper, T.nilable(Scraper))

    # response.stream.write('Hello!')
    # Check authentication
    # We're still allowing authentication via header so that old users
    # of the api don't have to change anything
    api_key = request.headers["HTTP_X_API_KEY"] || params[:key]
    if api_key.nil?
      render_error "API key is missing", 401
      return
    else
      owner = Owner.find_by(api_key: api_key)
      if owner.nil?
        render_error "API key is not valid", 401
        return
      end
    end

    begin
      respond_to do |format|
        format.sqlite { data_sqlite(scraper, owner) }
        format.json   { data_json(scraper, owner) }
        format.csv    { data_csv(scraper, owner)    }
        format.atom   { data_atom(scraper, owner)   }
      end
    rescue SQLite3::Exception => e
      render_error e.to_s, 400
    end
  ensure
    response.stream.close
  end

  private

  sig { params(scraper: Scraper, owner: Owner).void }
  def data_sqlite(scraper, owner)
    bench = Benchmark.measure do
      # Not just using send_file because we need to follow the pattern of the
      # rest of the controller
      File.open(scraper.database.sqlite_db_path, "rb") do |file|
        while (buff = file.read(16384))
          response.stream.write(buff)
        end
      end
      # For some reason the code below just copied across one 16k block
      # IO.copy_stream(scraper.database.sqlite_db_path, response.stream)
    end
    ApiQuery.log!(
      query: nil,
      scraper: scraper,
      owner: owner,
      benchmark: bench,
      size: scraper.database.sqlite_db_size,
      type: "database",
      format: "sqlite"
    )
  end

  sig { params(callback: T.nilable(String)).void }
  def json_header(callback)
    response.stream.write("/**/#{callback}(") if callback
    response.stream.write("[\n")
  end

  sig { params(callback: T.nilable(String)).void }
  def json_footer(callback)
    response.stream.write("\n]")
    response.stream.write(")\n") if callback
  end

  sig { params(scraper: Scraper, owner: Owner).void }
  def data_json(scraper, owner)
    params_query = T.cast(params[:query], String)
    params_callback = T.cast(params[:callback], T.nilable(String))

    # When calculating the size here we're ignoring a few bytes at the front and end
    size = 0
    bench = Benchmark.measure do
      # Tell nginx and passenger not to buffer this
      response.headers["X-Accel-Buffering"] = "no"
      mime_type = params[:callback] ? "application/javascript" : "application/json"
      response.headers["Content-Type"] = "#{mime_type}; charset=utf-8"
      i = 0
      scraper.database.sql_query_streaming(params_query) do |row|
        # In case there is an error with the query wait for that to work before
        # generating the first output
        if i.zero?
          json_header(params_callback)
        else
          response.stream.write("\n,")
        end
        s = row.to_json
        size += s.size
        response.stream.write(s)
        i += 1
      end
      # If there's no result make sure we also output the opening of the json
      json_header(params_callback) if i.zero?
      json_footer(params_callback)
    end
    ApiQuery.log!(
      query: params_query,
      scraper: scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: "sql",
      format: "json"
    )
  end

  # Returns the size of the header
  sig { params(row: T::Hash[String, String]).returns(Integer) }
  def csv_header(row)
    s = row.keys.to_csv
    response.stream.write(s)
    s.size
  end

  sig { params(scraper: Scraper, owner: Owner).void }
  def data_csv(scraper, owner)
    params_query = T.cast(params[:query], String)

    size = 0
    bench = Benchmark.measure do
      # Tell nginx and passenger not to buffer this
      response.headers["X-Accel-Buffering"] = "no"
      response.headers["Content-Disposition"] = "attachment; filename=#{scraper.name}.csv"
      displayed_header = T.let(false, T::Boolean)
      scraper.database.sql_query_streaming(params_query) do |row|
        # only show the header once at the beginning
        unless displayed_header
          size += csv_header(row)
          displayed_header = true
        end
        s = row.values.to_csv
        size += s.size
        response.stream.write(s)
      end
    end
    ApiQuery.log!(
      query: params_query,
      scraper: scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: "sql",
      format: "csv"
    )
  end

  sig { params(scraper: Scraper).void }
  def atom_header(scraper)
    response.stream.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    response.stream.write("<feed xmlns=\"http://www.w3.org/2005/Atom\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n")
    response.stream.write("  <title>morph.io: #{scraper.full_name}</title>\n")
    response.stream.write("  <subtitle>#{scraper.description}</subtitle>\n")
    response.stream.write("  <updated>#{DateTime.parse(scraper.updated_at.to_s).rfc3339}</updated>\n")
    response.stream.write("  <author>\n")
    response.stream.write("    <name>#{T.must(scraper.owner).name || T.must(scraper.owner).nickname}</name>\n")
    response.stream.write("  </author>\n")
    response.stream.write("  <id>#{request.protocol}#{request.host_with_port}#{request.fullpath}</id>\n")
    response.stream.write("  <link href=\"#{scraper_url(scraper)}\"/>\n")
    response.stream.write("  <link href=\"#{request.protocol}#{request.host_with_port}#{request.fullpath}\" rel=\"self\"/>\n")
  end

  sig { void }
  def atom_footer
    response.stream.write("</feed>\n")
  end

  sig { params(string: T.any(String, Date, DateTime)).returns(T.nilable(String)) }
  def parse_date(string)
    date = if string.is_a?(Date) || string.is_a?(DateTime)
             string
           else
             DateTime.parse(string)
           end
    date.rfc3339
  rescue ArgumentError
    nil
  end

  sig { params(scraper: Scraper, owner: Owner).void }
  def data_atom(scraper, owner)
    params_query = T.cast(params[:query], String)

    # Only measuring the size of the entry blocks. We're ignoring the header.
    size = 0
    bench = Benchmark.measure do
      # Tell nginx and passenger not to buffer this
      response.headers["X-Accel-Buffering"] = "no"
      displayed_header = T.let(false, T::Boolean)
      scraper.database.sql_query_streaming(params_query) do |row|
        unless displayed_header
          atom_header(scraper)
          displayed_header = true
        end
        s = +""
        s << "  <entry>\n"
        s << "    <title>#{row['title']}</title>\n"
        s << "    <content>#{row['content']}</content>\n"
        s << "    <link href=\"#{row['link']}\"/>\n"
        s << "    <id>#{row['link']}</id>\n"
        s << "    <updated>#{parse_date(row['date'])}</updated>\n"
        s << "  </entry>\n"
        size += s.size
        response.stream.write(s)
      end

      atom_header(scraper) unless displayed_header
      atom_footer
    end
    ApiQuery.log!(
      query: params_query,
      scraper: scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: "sql",
      format: "atom"
    )
  end

  sig { params(message: String, status: Integer).void }
  def render_error(message, status)
    response.status = status

    respond_to do |format|
      format.sqlite do
        response.content_type = "text"
        response.stream.write(message)
      end
      format.json do
        response.stream.write({ error: message }.to_json)
      end
      format.csv do
        response.content_type = "text"
        response.stream.write(message)
      end
      format.atom do
        response.content_type = "text"
        response.stream.write(message)
      end
    end
  end

  sig { void }
  def can_run
    return unless SiteSetting.read_only_mode

    render json: {
      stream: "internalerr",
      text: "You currently can't start a scraper run. " \
            "See https://morph.io for more details"
    }
  end

  sig { params(stream: Symbol, text: String).void }
  def stream_message(stream, text)
    line = { stream: stream, text: text }.to_json
    response.stream.write("#{line}\n")
  end

  sig { void }
  def authenticate_api_key
    render(plain: "API key is not valid", status: :unauthorized) if current_user.nil?
  end

  sig { returns(T.nilable(User)) }
  def current_user
    @current_user ||= T.let(User.find_by(api_key: params[:api_key]), T.nilable(User))
  end
end
