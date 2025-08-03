module ApiHelpers
  ITEMS_PER_PAGE = 20

  def build_jwt_header(token)
    { 'Authorization': "Bearer #{token}" }
  end
  
  def generate_password_hash(password)
    BCrypt::Password.create(password)
  end

  def password_match?(password, password_hash)
    BCrypt::Password.new(password_hash) == password
  end

  def decode_jwt(token)
    JWT.decode(token, Rails.application.secret_key_base)
  end

  def generate_jwt(user_object)
    payload = user_object
    payload[:exp] = 60.days.from_now.to_i

    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
