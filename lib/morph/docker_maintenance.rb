module Morph
  class DockerMaintenance
    def self.delete_container_and_remove_image(container)
      Rails.logger.info "Deleting container #{container}..."
      container.delete

      begin
        # Get container image ID and strip tag
        image_id = container.info["Image"].split(":").first
        i = Docker::Image.get(image_id)

        Rails.logger.info "Removing image #{i.id}..."
        i.remove
      rescue Docker::Error::ConfictError
        Rails.logger.warn "Conflict removing image, skipping..."
      rescue Docker::Error::NotFoundError
        Rails.logger.warn "Couldn't find container image, skipping..."
      end
    end
  end
end
