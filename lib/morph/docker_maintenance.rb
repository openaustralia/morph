module Morph
  class DockerMaintenance
    def self.delete_container_and_remove_image(container)
      delete_container(container)
      remove_image(container_image(container))
    end

    private

    def self.delete_container(container)
      Rails.logger.info "Deleting container #{container}..."
      container.delete
    end

    def self.container_image(container)
      image_id = container.info["Image"].split(":").first
      Docker::Image.get(image_id)
    end

    def self.remove_image
      Rails.logger.info "Removing image #{i.id}..."
      i.remove
    rescue Docker::Error::ConfictError
      Rails.logger.warn "Conflict removing image, skipping..."
    rescue Docker::Error::NotFoundError
      Rails.logger.warn "Couldn't find container image, skipping..."
    end
  end
end
