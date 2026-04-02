class User < ApplicationRecord
  ROLES = [
    "admin",
    "user"
  ]
  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :status, presence: true

  before_validation do
    if self.new_record? and self.status.blank?
      self.status = "pending"
    end

    if self.new_record? and self.role.blank?
      self.role = "user"
    end
  end

  scope :pending, -> { where(status: 'pending') }
  scope :active, -> { where(status: 'active') }
  scope :deleted, -> { where(status: 'deleted') }

  scope :search, -> (query) {
    where('first_name ILIKE :query OR last_name ILIKE :query OR username ILIKE :query', query: "%#{query}%")
  }

  def full_name
    "#{last_name}, #{first_name}"
  end

  def to_s
    full_name
  end

  def to_h
    to_object
  end

  def to_object
    {
      id: id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      full_name: full_name,
      role: role,
      status: status
    }
  end

  def admin?
    self.role == "admin"
  end

  def active?
    self.status == "active"
  end

  def inactive?
    self.status == "inactive"
  end

  def deleted?
    self.status == "deleted"
  end

  def soft_delete!
    self.update!(
      email: "deleted-#{SecureRandom.uuid_v7}-#{self.email}",
      status: 'deleted'
    )
  end
end
