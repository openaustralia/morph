set :stage, :production
set :rails_env, :production

role :app, %w{deploy@107.170.74.196}
role :web, %w{deploy@107.170.74.196}
role :db,  %w{deploy@107.170.74.196}
