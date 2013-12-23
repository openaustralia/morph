class User < ActiveRecord::Base
  # TODO Add :omniauthable
  devise :trackable, :omniauthable, :omniauth_providers => [:github]

  def self.find_for_github_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(nickname: auth.info.nickname, name:auth.info.name,
        provider:auth.provider, uid:auth.uid)
    end
    user
  end
end
