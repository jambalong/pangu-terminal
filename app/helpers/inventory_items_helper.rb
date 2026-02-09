module InventoryItemsHelper
  def inventory_card_classes(reconciliation)
    classes = [ "group" ]
    classes << "can-synthesize" if reconciliation&.dig(:synthesis_opportunity)
    classes << "used-higher-rarity" if reconciliation&.dig(:used_higher_rarity)
    classes.join(" ")
  end
end
