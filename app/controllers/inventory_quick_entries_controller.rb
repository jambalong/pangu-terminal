class InventoryQuickEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_list

  def show
  end

  def update
    @values = submitted_quantities
    result = InventoryBulkUpdater.call(user: current_user, quantities: @values)
    @errors = result[:errors]

    if @errors.any?
      render :show, status: :unprocessable_content
    else
      redirect_to inventory_quick_entry_path(all: (1 if @show_all)), notice: saved_message(result[:updated])
    end
  end

  private

  def load_list
    @show_all = params[:all].present?
    @list = InventoryQuickEntryList.call(user: current_user, show_all: @show_all)
  end

  # Only known material ids are read; anything else in the hash is dropped.
  def submitted_quantities
    raw = params[:quantities]
    raw.is_a?(ActionController::Parameters) ? raw.permit(*Material.ids.map(&:to_s)).to_h : {}
  end

  def saved_message(count)
    count.zero? ? "Nothing changed." : "Saved #{count} #{"material".pluralize(count)}."
  end
end
