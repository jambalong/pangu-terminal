class ApiKey < ApplicationRecord
  belongs_to :user

  attr_reader :raw_token

  validates :name, presence: true
  validate :api_key_limit

  before_create :generate_token

  def generate_token
    @raw_token = "pt_#{SecureRandom.urlsafe_base64(32)}"
    self.token = Digest::SHA256.hexdigest(@raw_token)
  end

  private

  def api_key_limit
    if user.api_keys.count >= 5
      errors.add(:base, "Maximum of 5 API Keys allowed")
    end
  end
end
