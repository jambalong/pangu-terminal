class FarmingAdvisorService < ApplicationService
  def initialize(results:, farming_priority:, sol3_phase:, chain_coverage:)
    @results = results
    @farming_priority = farming_priority
    @sol3_phase = sol3_phase
    @chain_coverage = chain_coverage
  end

  def call
    return nil if @results.blank? || @farming_priority.blank?

    LlmClient.ask(prompt)
  end

  private

  def prompt
    <<~PROMPT
      You are a sharp, knowledgeable guide helping a Rover navigate the lands of Solaris-3.
      The Rover is at SOL3 phase #{@sol3_phase}.

      Their current material deficits and farming estimates:
      #{format_deficits}

      Farming priority ranked by materials covered:
      #{format_priority}

      Give a short, specific recommendation. Name the source to hit first and why.
      If synthesis from lower-tier materials can meaningfully reduce farming runs, call it out.
      Write in a conversational tone, like a guide briefing a Rover before they head out.
      Keep it to 3-4 sentences. Do not invent any numbers not listed above.
    PROMPT
  end

  def format_deficits
    @results.map do |material_id, data|
      material = data[:material]
      deficit = data[:deficit]
      first_source = data[:sources].values.first
      chain = @chain_coverage[material_id]

      line = "- #{material.name} (rarity #{material.rarity}): deficit #{deficit}"
      line += ", estimated #{first_source[:estimated_runs]} runs at #{data[:sources].keys.first}" if first_source
      line += ", synthesis from lower tiers can cover #{chain} units" if chain

      line
    end.join("\n")
  end

  def format_priority
    @farming_priority.each_with_index.map do |entry, index|
      "#{index + 1}. #{entry[:source_labal]} - covers #{entry[:material_count]} #{"material".pluralize(entry[:material_count])}, #{entry[:waveplate_cost]} Waveplates/run"
    end.join("\n")
  end
end
