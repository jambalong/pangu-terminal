class FarmingPriorityService
  SOURCE_TYPE_LABELS = {
    "boss_challenge" => "Boss Challenge",
    "forgery_challenge" => "Forgery Challenge",
    "simulation_challenge" => "Simulation Challenge",
    "weekly_challenge" => "Weekly Challenge"
  }.freeze

  def initialize(results)
    @results = results
  end

  def call
    tally_sources
      .map { |type, data| build_entry(type, data) }
      .sort_by { |entry| [ -entry[:material_count], entry[:waveplate_cost] ] }
  end

  private

  def tally_sources
    @results.each_with_object({}) do | (_material_id, result), tally |
      unique_source_type_for(result).each do |source_type, waveplate_cost|
        tally[source_type] ||= { material_count: 0, waveplate_cost: waveplate_cost }
        tally[source_type][:material_count] += 1
      end
    end
  end

  def unique_source_type_for(result)
    result[:sources]
      .values
      .uniq { |s| s[:source_type] }
      .to_h { |s| [ s[:source_type], s[:waveplate_cost] ] }
  end

  def build_entry(source_type, data)
    {
      source_type: source_type,
      source_label: SOURCE_TYPE_LABELS.fetch(source_type, source_type.humanize),
      material_count: data[:material_count],
      waveplate_cost: data[:waveplate_cost]
    }
  end
end
