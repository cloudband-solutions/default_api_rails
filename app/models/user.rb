class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :status, presence: true

  before_validation do
    if self.new_record? and self.status.blank?
      self.status = "pending"
    end
  end

  scope :pending, -> { where(status: 'pending') }

  def full_name
    "#{last_name}, #{first_name}"
  end

  def to_s
    full_name
  end

  def to_object
    {
      id: id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      full_name: full_name,
      status: status
    }
  end

  def inactive?
    self.status == "inactive"
  end
end
