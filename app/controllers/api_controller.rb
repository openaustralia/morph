# Run API used by the morph command-line client
class ApiController < ApplicationController
  include ActionController::Live

  # The run_remote method will be secured with a key so shouldn't need csrf
  # token authentication
  skip_before_filter :verify_authenticity_token, only: [:run_remote]
  before_filter :authenticate_api_key, only: :run_remote
  before_filter :can_run, only: :run_remote

  # Receive code from a remote client, run it and return the result.
  # This will be a long running request
  # TODO: Document this API
  def run_remote
    response.headers['Content-Type'] = 'text/event-stream'
    run = Run.create(queued_at: Time.now, auto: false, owner: current_user)
    # TODO: Shouldn't need to untar here because it just gets retarred
    Archive::Tar::Minitar.unpack(params[:code].tempfile, run.repo_path)
    runner = Morph::Runner.new(run)
    runner.go { |timestamp, s, text| stream_message(s, text) }
  ensure
    # Cleanup run
    response.stream.close
    # Don't want to leave any containers hanging around
    container = runner.container_for_run
    if container
      container.kill
      container.delete
    end
    FileUtils.rm_rf(run.data_path)
    FileUtils.rm_rf(run.repo_path)
  end

  def data
    @scraper = Scraper.friendly.find(params[:id])
    #response.stream.write('Hello!')
    # Check authentication
    # We're still allowing authentication via header so that old users
    # of the api don't have to change anything
    api_key = request.headers['HTTP_X_API_KEY'] || params[:key]
    if api_key.nil?
      render_error 'API key is missing'
      return
    else
      owner = Owner.find_by_api_key(api_key)
      if owner.nil?
        render_error 'API key is not valid'
        return
      end
    end

    begin
      respond_to do |format|
        format.sqlite { data_sqlite(owner) }
        format.json   { data_json(owner)   }
        format.csv    { data_csv(owner)    }
        format.atom   { data_atom(owner)   }
      end

    rescue SQLite3::Exception => e
      render_error e.to_s
    end
  ensure
    response.stream.close
  end

  private

  def data_sqlite(owner)
    bench = Benchmark.measure do
      # Not just using send_file because we need to follow the pattern of the
      # rest of the controller
      File.open(@scraper.database.sqlite_db_path, 'rb') do |file|
        while buff = file.read(16384)
          response.stream.write(buff)
        end
      end
      # For some reason the code below just copied across one 16k block
      #IO.copy_stream(@scraper.database.sqlite_db_path, response.stream)
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: @scraper.database.sqlite_db_size,
      type: 'database',
      format: 'sqlite'
    )
  end

  def data_json(owner)
    # When calculating the size here we're ignoring a few bytes at the front and end
    size = 0
    bench = Benchmark.measure do
      # Tell nginx and passenger not to buffer this
      response.headers['X-Accel-Buffering'] = 'no'
      mime_type = params[:callback] ? 'application/javascript': 'application/json'
      response.headers['Content-Type'] = "#{mime_type}; charset=utf-8"
      response.stream.write("/**/#{params[:callback]}(")  if params[:callback]
      response.stream.write("[\n")
      i = 0
      @scraper.database.sql_query_streaming(params[:query]) do |row|
        response.stream.write("\n,") unless i == 0
        s = row.to_json
        size += s.size
        response.stream.write(s)
        i += 1
      end
      response.stream.write("\n]")
      response.stream.write(")\n") if params[:callback]
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: 'sql',
      format: 'json'
    )
  end

  def data_csv(owner)
    size = 0
    bench = Benchmark.measure do
      # Tell nginx and passenger not to buffer this
      response.headers['X-Accel-Buffering'] = 'no'
      response.headers["Content-Disposition"] = "attachment; filename=#{@scraper.name}.csv"
      displayed_header = false
      @scraper.database.sql_query_streaming(params[:query]) do |row|
        # only show the header once at the beginning
        unless displayed_header
          s = row.keys.to_csv
          size += s.size
          response.stream.write(s)
          displayed_header = true
        end
        s = row.values.to_csv
        size += s.size
        response.stream.write(s)
      end
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: 'sql',
      format: 'csv'
    )
  end

  def data_atom(owner)
    # Only measuring the size of the entry blocks. We're ignoring the header.
    size = 0
    bench = Benchmark.measure do
      # Tell nginx and passenger not to buffer this
      response.headers['X-Accel-Buffering'] = 'no'
      response.stream.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
      response.stream.write("<feed xmlns=\"http://www.w3.org/2005/Atom\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n")
      response.stream.write("  <title>morph.io: #{@scraper.full_name}</title>\n")
      response.stream.write("  <subtitle>#{@scraper.description}</subtitle>\n")
      response.stream.write("  <updated>#{DateTime.parse(@scraper.updated_at.to_s).rfc3339}</updated>\n")
      response.stream.write("  <author>\n")
      response.stream.write("    <name>#{@scraper.owner.name || @scraper.owner.nickname}</name>\n")
      response.stream.write("  </author>\n")
      response.stream.write("  <id>#{request.protocol}#{request.host_with_port}#{request.fullpath}</id>\n")
      response.stream.write("  <link href=\"#{scraper_url(@scraper)}\"/>\n")
      response.stream.write("  <link href=\"#{request.protocol}#{request.host_with_port}#{request.fullpath}\" rel=\"self\"/>\n")
      @scraper.database.sql_query_streaming(params[:query]) do |row|
        s = ""
        s << "  <entry>\n"
        s << "    <title>#{row['title']}</title>\n"
        s << "    <content>#{row['content']}</content>\n"
        s << "    <link href=\"#{row['link']}\"/>\n"
        s << "    <id>#{row['link']}</id>\n"
        s << "    <updated>#{DateTime.parse(row['date']).rfc3339 rescue nil}</updated>\n"
        s << "  </entry>\n"
        size += s.size
        response.stream.write(s)
      end
      response.stream.write("</feed>\n")
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: 'sql',
      format: 'atom'
    )
  end

  def render_error(message)
    respond_to do |format|
      format.sqlite { render text: message, status: 401, content_type: :text }
      format.json { render json: { error: message }, status: 401 }
      format.csv { render text: message, status: 401, content_type: :text }
      format.atom { render text: message, status: 401, content_type: :text }
    end
  end

  def can_run
    return if current_user.ability.can? :create, Run

    render json: {
      stream: 'internalerr',
      text: "You currently can't start a scraper run." \
            ' See https://morph.io for more details'
    }
  end

  def stream_message(stream, text)
    response.stream.write({ stream: stream, text: text }.to_json + "\n")
  end

  def authenticate_api_key
    render(text: 'API key is not valid', status: 401) if current_user.nil?
  end

  def current_user
    @current_user ||= User.find_by_api_key(params[:api_key])
  end
end
