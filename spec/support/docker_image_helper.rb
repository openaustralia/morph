module DockerImageHelper
  def pull_image_if_missing(image_name)
    return if Docker::Image.exist?(image_name)

    puts "Pulling #{image_name}..."
    Docker::Image.create("fromImage" => image_name)
  rescue Docker::Error::NotFoundError => e
    raise "Required Docker image '#{image_name}' not found: #{e.message}"
  end
end