json.array! @users do |user|
  json.created_at user.created_at
  json.nickname user.nickname
end
