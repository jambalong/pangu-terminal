module Api
  module V1
    class MaterialsController < Api::V1::BaseController
      def index
        materials = Material.includes(:sources).all

        render json: materials.map { |material| MaterialSerializer.new(material).to_h }
      end
    end
  end
end
