class FarmingAdvisorService < ApplicationService
  def initialize(results:, farming_priority:, sol3_phase:, chain_coverage:)
    @results = results
    @farming_priority = farming_priority
    @sol3_phase = sol3_phase
    @chain_coverage = chain_coverage
  end

  def call
    return nil if @results.blank?

    LlmClient.ask(prompt)
  end

  private

  def prompt
    <<~PROMPT
      You are a helpful, calm field guide briefing a Rover before they head out in Solaris-3.
      Always address the Rover directly. Keep your tone practical and encouraging, like a knowledgeable companion giving clear advice.
      The Rover is at SOL3 phase #{@sol3_phase}.

      Material deficits, farming estimates, and synthesis opportunities:
      #{format_deficits}

      Note: materials with type enemy_drop have no Waveplate farming source. They must be hunted from open-world enemies. They CAN be partially or fully covered through synthesis if lower tier surplus exists.
      Materials with type flower have no Waveplate farming source and cannot be synthesized. They must be gathered from fixed open-world locations.

      Farming priority ranked by efficiency:
      #{format_priority}

      Note: Prioritize Weekly Challenge/boss_drop material when available. It has 3 runs available per week and resets weekly.

      Give a specific recommendation in 3-4 sentences. Name the source to hit first and why.
      Always phrase advice in forward-looking terms. For example, say "you can cover X through synthesis, so no farming needed" rather than "you have already covered X".
      If synthesis fully covers a deficit, tell the Rover they do not need to farm that material.
      If synthesis partially covers a deficit, tell the Rover how much farming is still needed.
      If an enemy_drop deficit is not covered by synthesis, tell the Rover they need to hunt for it in the open world.
      If a flower deficit exists, tell the Rover they need to gather it from the open world.
      Use only the numbers provided above. Do not use em dashes.
    PROMPT
  end

  def format_deficits
    @results.map do |material_id, data|
      material = data[:material]
      deficit = data[:deficit]
      first_source = data[:sources].values.first
      chain = @chain_coverage[material_id]

      line = "- #{material.name} (rarity #{material.rarity}, type: #{material.material_type}): deficit #{deficit}"
      line += " [no Waveplate source, open-world gather only]" if material.material_type == "flower"
      line += " [no Waveplate source, open-world hunt only]" if material.material_type == "enemy_drop"
      line += ", estimated #{first_source[:estimated_runs]} runs at #{data[:sources].keys.first}" if first_source

      if chain && !no_waveplate_source?(material)
        if chain >= deficit
          line += ", synthesis fully covers this deficit -- no farming needed"
        else
          line += ", synthesis from lower tiers can cover #{chain} units, #{deficit - chain} still needed"
        end
      end

      line
    end.join("\n")
  end

  def format_priority
    @farming_priority.each_with_index.map do |entry, index|
      "#{index + 1}. #{entry[:source_label]} - covers #{entry[:material_count]} #{"material".pluralize(entry[:material_count])}, #{entry[:waveplate_cost]} Waveplates/run"
    end.join("\n")
  end

  def no_waveplate_source?(material)
    material.material_type == "flower"
  end
end
