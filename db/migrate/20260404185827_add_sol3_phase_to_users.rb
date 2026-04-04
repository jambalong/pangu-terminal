class AddSol3PhaseToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sol3_phase, :integer
  end
end
