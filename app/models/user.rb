class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: OauthProviders.names

  has_many :identities, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :materials, through: :inventory_items

  # The gamertag shown in the navbar: lowercase, short enough to never need an
  # ellipsis. Only checked when it changes so older, longer names stay valid.
  DISPLAY_NAME_LENGTH = 3..16
  DISPLAY_NAME_FORMAT = /\A[a-z0-9][a-z0-9._-]*\z/

  validates :display_name,
            length: { within: DISPLAY_NAME_LENGTH },
            format: { with: DISPLAY_NAME_FORMAT, message: "can only use lowercase letters, numbers, dots, dashes and underscores" },
            allow_nil: true,
            if: :will_save_change_to_display_name?
  validates :sol3_phase, inclusion: { in: DropRate::SOL3_PHASES }, allow_nil: true

  before_validation :normalize_blank_email
  before_validation :normalize_display_name
  after_create :initialize_inventory

  # Neutral default so no real name is ever taken from a provider.
  def self.generate_display_name
    "rover-#{SecureRandom.random_number(1000..9999)}"
  end

  # Name shown in the navbar. Never exposes an email beyond its local part.
  def shown_name
    display_name.presence || email.to_s.split("@").first.presence || "Account"
  end

  def password?
    encrypted_password.present?
  end

  # Accounts created through OAuth have no password and may have no email.
  def oauth_only?
    !password? && identities.any?
  end

  # A way to sign in that does not depend on the identity being removed.
  def can_unlink?(identity)
    identities.reject { |other| other == identity }.any? || (password? && email.present?)
  end

  def inventory_item_for(material)
    inventory_items.find_or_create_by!(material: material) do |item|
      item.quantity = 0
    end
  end

  protected

  # Password users still need an email to sign in; OAuth-only users do not.
  def email_required?
    !oauth_only?
  end

  def password_required?
    return false if oauth_only? && password.blank? && password_confirmation.blank?
    super
  end

  private

  def normalize_display_name
    return unless will_save_change_to_display_name?

    self.display_name = display_name.to_s.strip.downcase.presence
  end

  def normalize_blank_email
    self.email = nil if email.blank?
  end

  def initialize_inventory
    materials = Material.pluck(:id).map do |mat_id|
      {
        user_id: id,
        material_id: mat_id,
        quantity: 0,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    InventoryItem.insert_all(materials)
  end
end
