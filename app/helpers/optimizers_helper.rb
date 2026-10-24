module OptimizersHelper
  # Heading for the optimizer's plan card: one plan by name, otherwise a count.
  def selection_title(plans, all_selected)
    return plans.first.subject.name if plans.one? && !all_selected

    all_selected ? "All plans (#{plans.size})" : "#{plans.size} plans"
  end

  def selection_subtitle(plans, all_selected)
    return "#{plans.first.subject_type.upcase} PLAN LOADED" if plans.one? && !all_selected

    truncate(plans.map { |plan| plan.subject.name }.to_sentence(last_word_connector: ", "), length: 70)
  end

  def material_card_attrs(data)
    attrs = { class: "optimizer-material-card" }
    if data[:sources].empty?
      attrs[:class] += " hidden"
      attrs[:data] = { toggle_target: "item" }
    end
    attrs
  end
end
