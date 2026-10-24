# The materials shown on the quick entry page, grouped by category in game
# order. By default only what the user's plans need (or everything when they
# have no plans, or when show_all is set), each with the quantity they own and
# the total their plans need.
class InventoryQuickEntryList < ApplicationService
  def initialize(user:, show_all: false)
    @user = user
    @show_all = show_all
  end

  def call
    needed = needed_by_plans
    only_needed = !@show_all && needed.any?
    owned = @user.inventory_items.pluck(:material_id, :quantity).to_h

    materials = Material.order(:id).to_a
    materials = materials.select { |material| needed.key?(material.id) } if only_needed

    groups = materials.group_by(&:category).sort_by { |category, _| Material::CATEGORY_ORDER.index(category) || Material::CATEGORY_ORDER.size }

    {
      showing_all: !only_needed,
      has_plans: needed.any?,
      groups: groups.map do |category, items|
        { category: category, items: items.map { |material| { material: material, owned: owned.fetch(material.id, 0), needed: needed[material.id] } } }
      end
    }
  end

  private

  def needed_by_plans
    @user.plans.each_with_object(Hash.new(0)) do |plan, totals|
      (plan.plan_data["output"] || {}).each { |material_id, quantity| totals[material_id.to_i] += quantity }
    end.select { |_id, quantity| quantity.positive? }
  end
end
