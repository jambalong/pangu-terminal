class ApiKey < ApplicationRecord
  belongs_to :user

  has_secure_token :token, length: 36

  validates :name, presence: true
end
