# Reads and writes the two inventory file formats, with no dependencies (Ruby 3.4
# no longer bundles a CSV library).
#
# JSON is the same flat map the API returns: {"shell_credit": 120000, ...}; an
# array of {"key" or "name", "quantity"} objects is accepted too.
# CSV has the header key,name,quantity. On import a header row is optional, the
# delimiter may be a comma, semicolon or tab (spreadsheets differ by locale), and
# a material may be named by key or by name.
#
# parse returns { rows: [{ ident:, quantity:, where: }], error: nil } where
# `where` is a human label ("line 4", "entry 2") used when reporting skipped rows.
module InventoryTable
  IDENT_HEADERS = %w[ key name material ].freeze
  QUANTITY_HEADERS = %w[ quantity qty owned amount count ].freeze
  DELIMITERS = [ ",", ";", "\t" ].freeze

  module_function

  def parse(text)
    text = text.to_s.dup.force_encoding(Encoding::UTF_8)
    return { rows: [], error: "The file is not valid UTF-8 text." } unless text.valid_encoding?

    text = text.delete_prefix("﻿").strip
    return { rows: [], error: "The file is empty." } if text.empty?

    text.start_with?("{", "[") ? parse_json(text) : parse_csv(text)
  end

  def to_csv(entries)
    lines = [ "key,name,quantity" ]
    entries.each { |entry| lines << [ entry[:key], entry[:name], entry[:quantity] ].map { |field| csv_field(field) }.join(",") }
    lines.join("\r\n") + "\r\n"
  end

  def csv_field(value)
    value = value.to_s
    value.match?(/[",\r\n]/) ? "\"#{value.gsub('"', '""')}\"" : value
  end

  def parse_json(text)
    data = JSON.parse(text)
    data = data.values.first if data.is_a?(Hash) && data.size == 1 && %w[ inventory items materials ].include?(data.keys.first)

    rows =
      case data
      when Hash
        data.each_with_index.map { |(ident, quantity), index| { ident: ident.to_s, quantity: quantity, where: "entry #{index + 1} (#{ident})" } }
      when Array
        data.each_with_index.map { |item, index| json_array_row(item, index + 1) }
      else
        return { rows: [], error: "The JSON must be an object of key to quantity, or a list of entries." }
      end

    { rows: rows, error: nil }
  rescue JSON::ParserError
    { rows: [], error: "The JSON could not be read. Check for a missing comma or quote." }
  end

  def json_array_row(item, number)
    return { ident: nil, quantity: nil, where: "entry #{number}" } unless item.is_a?(Hash)

    ident = item.values_at(*IDENT_HEADERS).compact.first
    quantity = item.values_at(*QUANTITY_HEADERS).compact.first
    { ident: ident&.to_s, quantity: quantity, where: "entry #{number}" }
  end

  def parse_csv(text)
    records = read_csv(text)
    return { rows: [], error: "No rows were found." } if records.empty?

    header = header_map(records.first[:fields])
    records = records.drop(1) if header
    ident_at = header ? header[:ident] : 0
    quantity_at = header ? header[:quantity] : (records.first && records.first[:fields].size >= 2 ? records.first[:fields].size - 1 : 1)

    rows = records.map do |record|
      { ident: record[:fields][ident_at].to_s.strip, quantity: record[:fields][quantity_at], where: "line #{record[:line]}" }
    end
    { rows: rows, error: nil }
  end

  def header_map(fields)
    names = fields.map { |field| field.to_s.strip.downcase }
    ident = names.index { |name| IDENT_HEADERS.include?(name) }
    quantity = names.index { |name| QUANTITY_HEADERS.include?(name) }
    return nil unless ident && quantity

    # When both key and name columns exist, prefer the key (it never has spelling variants).
    ident = names.index("key") || ident
    { ident: ident, quantity: quantity }
  end

  # Minimal RFC 4180 reader: quoted fields, doubled quotes, newlines inside quotes.
  def read_csv(text)
    delimiter = detect_delimiter(text)
    records = []
    fields = []
    field = +""
    quoted = false
    line = 1
    start_line = 1
    chars = text.gsub("\r\n", "\n").tr("\r", "\n").chars
    index = 0

    finish_record = lambda do
      fields << field
      field = +""
      records << { fields: fields, line: start_line } unless fields.all? { |value| value.strip.empty? }
      fields = []
    end

    while index < chars.size
      char = chars[index]
      if quoted
        if char == '"' && chars[index + 1] == '"'
          field << '"'
          index += 1
        elsif char == '"'
          quoted = false
        else
          field << char
          line += 1 if char == "\n"
        end
      elsif char == '"' && field.empty?
        quoted = true
      elsif char == delimiter
        fields << field
        field = +""
      elsif char == "\n"
        finish_record.call
        line += 1
        start_line = line
      else
        field << char
      end
      index += 1
    end
    finish_record.call unless field.empty? && fields.empty?
    records
  end

  def detect_delimiter(text)
    first_line = text.lines.find { |line| line.strip.present? }.to_s
    DELIMITERS.max_by { |delimiter| first_line.count(delimiter) }.then { |best| first_line.count(best).zero? ? "," : best }
  end
end
