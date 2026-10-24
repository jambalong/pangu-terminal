module OptimizersHelper
  # "Ready now", "45 min", "7 h 30 min", "9 days 6 h": a duration in plain words.
  def waveplate_duration(minutes)
    return "Ready now" if minutes <= 0

    days, rest = minutes.divmod(24 * 60)
    hours, mins = rest.divmod(60)

    parts = []
    parts << "#{days} #{"day".pluralize(days)}" if days.positive?
    parts << "#{hours} h" if hours.positive?
    parts << "#{mins} min" if mins.positive? && days.zero?
    parts.join(" ")
  end

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
