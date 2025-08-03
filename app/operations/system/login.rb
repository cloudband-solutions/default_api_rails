module System
  class Login < Validator
    attr_reader :email, :password, :user, :payload

    include ApiHelpers

    def initialize(email:, password:)
      super()

      @email    = email
      @password = password

      @payload = {
        email:    [],
        password: []
      }
    end

    def execute!
      if @email.present?
        @user = User.find_by_email(@email)
      end

      if @email.blank?
        @payload[:email] << "email required"
      elsif @user.blank?
        @payload[:email] << "user not found"
      end
      
      if @password.blank?
        @payload[:password] << "password required"
      end

      if @user.present? and @password.present?
        if !password_match?(@password, @user.encrypted_password)
          @payload[:password] << "invalid password"
        elsif @user.inactive?
          @payload[:email] << "user inactive"
        end
      end

      count_errors!
    end
  end
end
