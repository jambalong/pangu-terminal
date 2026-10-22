# Which forgery/material set a Resonator or weapon uses. Seeds set it
# (db/seeds/01_resonators.rb, 02_weapons.rb); the planners read it to pick the
# matching weapon_type_materials rows.
module ForgeryRegion
  extend ActiveSupport::Concern

  REGIONS = %w[base lahai_roi].freeze

  included do
    validates :region, inclusion: { in: REGIONS }
  end
end
