# Turns what a person typed (or a file contained) into a whole, non-negative
# quantity, or nil when it is not one. "1,200", "1 200", "5.0" and 5 are all
# fine; with suffixes: true, "25k" and "1.5m" work too (typing, not files).
module QuantityParser
  MAX = 2_000_000_000
  SUFFIXES = { "k" => 1_000, "m" => 1_000_000 }.freeze

  module_function

  def parse(raw, suffixes: false)
    case raw
    when Integer then raw.negative? ? nil : raw
    when Float then raw >= 0 && raw == raw.to_i ? raw.to_i : nil
    when String then parse_string(raw, suffixes)
    end
  end

  def parse_string(raw, suffixes)
    cleaned = raw.strip.delete(", _ ").downcase
    return cleaned.to_i if cleaned.match?(/\A\d+(\.0+)?\z/)
    return nil unless suffixes

    match = cleaned.match(/\A(\d+(?:\.\d+)?)([km])\z/)
    return nil unless match

    value = (BigDecimal(match[1]) * SUFFIXES.fetch(match[2]))
    value.frac.zero? ? value.to_i : nil
  end
end
