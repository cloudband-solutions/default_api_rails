module Users
  class Save < Validator
    attr_reader :payload, :user

    include ApiHelpers

    def initialize(
      user: nil,
      email:,
      first_name:,
      last_name:,
      password:,
      password_confirmation:
    )
      super()

      @user                   = user
      @email                  = email
      @first_name             = first_name
      @last_name              = last_name
      @password               = password
      @password_confirmation  = password_confirmation

      @payload = {
        email: [],
        first_name: [],
        last_name: [],
        password: [],
        password_confirmation: []
      }
    end

    def execute!
      self.validate!

      if self.valid?
        if @user.blank?
          @user = User.new(
            email:                  @email,
            first_name:             @first_name,
            last_name:              @last_name,
            encrypted_password:     generate_password_hash(@password),
          )
        else
          @user.email = @email if @email.present?
          @user.first_name = @first_name if @first_name.present?
          @user.last_name = @last_name if @last_name.present?
        end

        @user.save!
      end
    end

    private

    def validate!
      if @user.blank?
        if @email.blank?
          @payload[:email] << "required"
        elsif (@email =~ URI::MailTo::EMAIL_REGEXP).nil?
          @payload[:email] << "invalid format"
        elsif User.find_by_email(@email).present?
          @payload[:email] << "already taken"
        end

        if @first_name.blank?
          @payload[:first_name] << "required"
        end

        if @last_name.blank?
          @payload[:last_name] << "required"
        end

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
      else
        if @email.present? 
          if User.where.not(id: @user.id).find_by_email(@email).present?
            @payload[:email] << "already taken"
          elsif (@email =~ URI::MailTo::EMAIL_REGEXP).nil?
            @payload[:email] << "invalid format"
          end
        end
      end

      count_errors!
    end
  end
end
