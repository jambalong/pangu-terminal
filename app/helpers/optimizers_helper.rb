module OptimizersHelper
  def material_card_attrs(data)
    attrs = { class: "optimizer-material-card" }
    if data[:sources].empty?
      attrs[:class] += " hidden"
      attrs[:data] = { toggle_target: "item" }
    end
    attrs
  end
end
