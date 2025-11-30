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
      status: status
    }
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
    self.update!(status: 'deleted')
  end
end
