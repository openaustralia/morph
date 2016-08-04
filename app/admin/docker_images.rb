ActiveAdmin.register_page 'Docker Images' do
  content do
    images = Docker::Image.all
    table do
      thead do
        tr do
          th 'ID'
          th 'Created'
          th 'Last used by run'
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
              time = Run.where(docker_image: image.id[0..11]).maximum(:created_at)
              time_ago_in_words(time) + ' ago' if time
            end
          end
        end
      end
    end
  end
end
