class MaterialSerializer
  def initialize(material)
    @material = material
  end

  def to_h
    {
      material_key: @material.snake_case_name,
      display_name: @material.name,
      rarity: @material.rarity,
      material_type: @material.material_type,
      sources: sources
    }
  end

  private

  def sources
    @material.sources.map do |source|
      {
        name: source.name,
        source_type: source.source_type,
        waveplate_cost: source.waveplate_cost,
        location: source.location,
        region: source.region
      }
    end
  end
end
