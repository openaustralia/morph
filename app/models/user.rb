class User < ActiveRecord::Base
  # TODO Add :omniauthable
  devise :trackable
end
