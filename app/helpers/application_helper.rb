module ApplicationHelper
  DEFAULT_DESCRIPTION = "Plan Wuthering Waves material costs, track your inventory, see what you can craft instead of farm, and know where your next Waveplate goes. Free and fan-made.".freeze

  # Public URL on the canonical host, whichever hostname served the request.
  def canonical_url(path = request.path)
    "https://#{ENV.fetch("APP_HOST", "panguterminal.ambalong.dev")}#{path}"
  end

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
