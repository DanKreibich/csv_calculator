class AddFileNameAndCarbonToCarbonRecord < ActiveRecord::Migration[6.0]
  def change
    add_column :carbon_records, :co2_in_g, :integer
    add_column :carbon_records, :file_name, :string
  end
end
