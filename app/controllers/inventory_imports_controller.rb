class InventoryImportsController < ApplicationController
  MAX_BYTES = 1.megabyte

  before_action :authenticate_user!

  def new
  end

  def create
    content, @error = read_content

    if @error
      render :new, status: :unprocessable_content
    else
      @result = InventoryImporter.call(user: current_user, content: content)
      @error = @result[:error]
      render :new, status: (@error ? :unprocessable_content : :ok)
    end
  end

  private

  # Returns [text, nil] or [nil, error message]. The upload wins over pasted text.
  def read_content
    file = params[:file]

    if file.respond_to?(:read)
      return [ nil, "That file is too large (the limit is 1 MB)." ] if file.size > MAX_BYTES

      [ file.read, nil ]
    elsif params[:data].to_s.present?
      return [ nil, "That text is too large (the limit is 1 MB)." ] if params[:data].to_s.bytesize > MAX_BYTES

      [ params[:data].to_s, nil ]
    else
      [ nil, "Choose a file or paste your inventory first." ]
    end
  end
end
