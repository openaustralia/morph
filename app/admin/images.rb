ActiveAdmin.register_page 'Images' do
  content do
    images = Docker::Image.all
    table do
      thead do
        tr do
          th 'ID'
          th 'Created'
          th 'Last used'
        end
      end
      tbody do
        images.each do |image|
          tr do
            td image.id
            td do
              time_ago_in_words(Time.at(image.info['Created'])) + ' ago'
            end
            td do
              docker_image = image.id[0..11]
              p docker_image
              time = Run.where(docker_image: docker_image).maximum(:created_at)
              time_ago_in_words(time) + ' ago' if time
            end
          end
        end
      end
    end
  end
end
