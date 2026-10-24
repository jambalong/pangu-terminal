class InventoryExportsController < ApplicationController
  before_action :authenticate_user!

  # GET /app/inventory/export.csv or .json: the whole inventory, one entry per
  # material. The JSON is the same flat key => quantity map the API returns.
  def show
    entries = InventoryExporter.call(user: current_user)
    stamp = Date.current.iso8601

    respond_to do |format|
      format.csv do
        send_data InventoryTable.to_csv(entries), filename: "pangu-inventory-#{stamp}.csv",
                  type: "text/csv; charset=utf-8", disposition: "attachment"
      end
      format.json do
        send_data JSON.pretty_generate(entries.to_h { |entry| [ entry[:key], entry[:quantity] ] }),
                  filename: "pangu-inventory-#{stamp}.json", type: "application/json", disposition: "attachment"
      end
    end
  end
end
