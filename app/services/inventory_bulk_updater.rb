# Saves the quick entry form: a hash of material id => what was typed. It is
# all or nothing: if any entry cannot be read as a quantity nothing is saved and
# each bad entry is returned with a message, so the person can fix it and resubmit.
# A blank entry means zero. Unknown material ids are ignored.
class InventoryBulkUpdater < ApplicationService
  def initialize(user:, quantities:)
    @user = user
    @quantities = quantities.to_h.transform_keys(&:to_i)
  end

  def call
    materials = Material.where(id: @quantities.keys).index_by(&:id)
    parsed = {}
    errors = {}

    @quantities.each do |material_id, raw|
      material = materials[material_id] or next
      value = raw.to_s.strip.empty? ? 0 : QuantityParser.parse(raw.to_s, suffixes: true)

      if value.nil?
        errors[material_id] = "Enter a whole number, such as 1200, 1,200 or 25k."
      elsif value > QuantityParser::MAX
        errors[material_id] = "That is more than #{ActiveSupport::NumberHelper.number_to_delimited(QuantityParser::MAX)}."
      else
        parsed[material.id] = value
      end
    end

    return { updated: 0, errors: errors } if errors.any?

    { updated: save(parsed), errors: {} }
  end

  private

  def save(parsed)
    existing = @user.inventory_items.where(material_id: parsed.keys).index_by(&:material_id)
    changed = parsed.select { |material_id, quantity| (existing[material_id]&.quantity || 0) != quantity }

    if changed.any?
      InventoryItem.upsert_all(
        changed.map { |material_id, quantity| { user_id: @user.id, material_id: material_id, quantity: quantity } },
        unique_by: [ :user_id, :material_id ]
      )
    end

    changed.size
  end
end
