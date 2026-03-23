module InventoryItemsHelper
  def inventory_card_classes(reconciliation)
    classes = [ "group" ]
    classes << "can-synthesize" if reconciliation&.dig(:craftable_count)
    classes << "used-higher-rarity" if reconciliation&.dig(:used_higher_rarity)
    classes.join(" ")
  end

  def rarity_border_class(rarity)
    "rarity-border-#{rarity}"
  end

  def rarity_bg_class(rarity)
    "rarity-bg-#{rarity}"
  end
end
