class ApiKey < ApplicationRecord
  belongs_to :user

  attr_reader :raw_token

  validates :name, presence: true

  before_create :generate_token

  def generate_token
    @raw_token = "pt_#{SecureRandom.urlsafe_base64(32)}"
    self.token = Digest::SHA256.hexdigest(@raw_token)
  end
end
