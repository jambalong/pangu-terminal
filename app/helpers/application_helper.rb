module ApplicationHelper
  def format_quantity(number)
    return "0" if number.zero?
    return number.to_s if number < 1000

    # number_to_human handles the k, M, B suffixes automatically
    number_to_human(number,
      units: { thousand: "k", million: "M", billion: "B" },
      precision: 2,
      strip_insignificant_zeros: true,
      format: "%n%u"
    )
  end
end
