# Applies an inventory file (see InventoryTable for the formats) to a user's
# inventory. Materials are matched by key or by name; only quantities change and
# materials the file does not mention are left alone. Rows that cannot be used
# are skipped and reported, never guessed at, and the rest are applied together.
class InventoryImporter < ApplicationService
  MAX_QUANTITY = QuantityParser::MAX
  MAX_ROWS = 5_000

  def initialize(user:, content:)
    @user = user
    @content = content
  end

  def call
    parsed = InventoryTable.parse(@content)
    return failure(parsed[:error]) if parsed[:error]
    return failure("The file has no rows to import.") if parsed[:rows].empty?
    return failure("The file has too many rows (the limit is #{MAX_ROWS}).") if parsed[:rows].size > MAX_ROWS

    skipped = []
    changes = {}
    seen = {}

    parsed[:rows].each do |row|
      material = find_material(row[:ident])
      quantity = QuantityParser.parse(row[:quantity])

      if row[:ident].blank?
        skipped << skip(row, "no material name or key")
      elsif material.nil?
        skipped << skip(row, "unknown material #{row[:ident].to_s.truncate(40).inspect}")
      elsif quantity.nil?
        skipped << skip(row, "#{row[:quantity].to_s.truncate(20).inspect} is not a whole number")
      elsif quantity > MAX_QUANTITY
        skipped << skip(row, "#{quantity} is larger than #{MAX_QUANTITY}")
      else
        skipped << { where: seen[material.id], reason: "#{material.name} is listed again later; the later line wins" } if seen.key?(material.id)
        seen[material.id] = row[:where]
        changes[material.id] = quantity
      end
    end

    apply(changes).merge(skipped: skipped, error: nil)
  end

  private

  def apply(changes)
    existing = @user.inventory_items.where(material_id: changes.keys).index_by(&:material_id)
    changed = changes.select { |material_id, quantity| (existing[material_id]&.quantity || 0) != quantity }

    if changed.any?
      InventoryItem.upsert_all(
        changed.map { |material_id, quantity| { user_id: @user.id, material_id: material_id, quantity: quantity } },
        unique_by: [ :user_id, :material_id ]
      )
    end

    { updated: changed.size, unchanged: changes.size - changed.size }
  end

  def failure(message)
    { updated: 0, unchanged: 0, skipped: [], error: message }
  end

  def skip(row, reason)
    { where: row[:where], reason: reason }
  end

  def find_material(ident)
    return nil if ident.blank?

    materials_by_key[ident.to_s.strip.downcase] || materials_by_name[normalize(ident)]
  end

  def materials_by_key
    @materials_by_key ||= all_materials.index_by(&:snake_case_name)
  end

  def materials_by_name
    @materials_by_name ||= all_materials.index_by { |material| normalize(material.name) }
  end

  def all_materials
    @all_materials ||= Material.all.to_a
  end

  def normalize(text)
    text.to_s.downcase.gsub(/\s+/, " ").strip
  end
end
