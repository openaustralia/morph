# typed: false
# frozen_string_literal: true

ActiveAdmin.register_page "Docker Images" do
  content do
    images = Docker::Image.all
    table do
      thead do
        tr do
          th "ID"
          th "Created"
          th "Last used by run"
        end
      end
      tbody do
        images.each do |image|
          tr do
            td image.id
            td do
              "#{time_ago_in_words(Time.zone.at(image.info['Created']))} ago"
            end
            td do
              # We're getting an image id which is in a different form than
              # the one that's stored in the database
              image_id = image.id.split(":")[1][0..11]
              time = Run.where(docker_image: image_id).maximum(:created_at)
              "#{time_ago_in_words(time)} ago" if time
            end
          end
        end
      end
    end
  end
end
