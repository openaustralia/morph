class DockerRunner
  def self.run(options)
    Docker.options[:read_timeout] = 3600
    Docker.options[:chunk_size] = 1

    # This will fail if there is another container with the same name
    c = Docker::Container.create("Cmd" => ['/bin/bash', '-l', '-c', options[:command]],
      "User" => "scraper",
      "Image" => options[:image_name],
      "name" => options[:container_name])

    # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
    # HACK to detect vagrant installation in crude way
    if Rails.root.to_s =~ /\/var\/www/
      local_root_path = Rails.root
    else
      local_root_path = "/vagrant"
    end

    begin
      c.start("Binds" => [
        "#{local_root_path}/#{options[:repo_path]}:/repo:ro",
        "#{local_root_path}/#{options[:data_path]}:/data"
      ])
      puts "Running docker container..."
      c.attach(logs: true) do |s,c|
        yield s,c
      end
    ensure
      # This appears to be giving a broken pipe (Errno::EPIPE) sometimes
      if c.json["State"]["Running"]
        c.kill 
      end
    end
    # Scraper should already have finished now. We're just using this to return the scraper status code
    status_code = c.wait["StatusCode"]

    # Clean up after ourselves
    c.delete

    status_code
  end
end
