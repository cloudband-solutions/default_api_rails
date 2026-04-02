module System
  class ChangePassword < Validator
    attr_reader :payload, :user

    include ApiHelpers

    def initialize(user:, password:, password_confirmation:)
      super()

      @user = user
      @password = password
      @password_confirmation = password_confirmation
      @payload = {
        password: [],
        password_confirmation: []
      }
    end

    def execute!
      validate!

      if valid?
        @user.update!(
          encrypted_password: generate_password_hash(@password)
        )
      end
    end

    private

    def validate!
      if @password.blank?
        @payload[:password] << "required"
      end

      if @password_confirmation.blank?
        @payload[:password_confirmation] << "required"
      end

      if @password.present? and @password_confirmation.present? and @password != @password_confirmation
        @payload[:password] << "does not match"
        @payload[:password_confirmation] << "does not match"
      end

      count_errors!
    end
  end
end
