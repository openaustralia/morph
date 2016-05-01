module Morph
  class DockerMaintenance
    def self.delete_container_and_remove_image(container)
      delete_container(container)
      remove_image(container_image_id(container))
    end

    def self.delete_container_and_remove_image_safe(container)
      begin
        delete_container_and_remove_image(container)
      rescue Exception => e
        Rails.logger.warn "Exception while removing container #{container.id}: #{e.inspect}"
      end
    end

    def self.remove_image(image_id)
      Rails.logger.info "Removing image #{image_id}..."
      Docker::Image.get(image_id).remove
    rescue Docker::Error::ConfictError
      Rails.logger.warn "Conflict removing image, skipping..."
    rescue Docker::Error::NotFoundError
      Rails.logger.warn "Couldn't find container image, skipping..."
    end

    private

    def self.delete_container(container)
      Rails.logger.info "Deleting container #{container.id}..."
      container.delete
    end

    def self.container_image_id(container)
      container.info["Image"].split(":").first
    end
  end
end
