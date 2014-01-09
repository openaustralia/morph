set :stage, :production

role :app, %w{deploy@morph.io}
role :web, %w{deploy@morph.io}
role :db,  %w{deploy@morph.io}
