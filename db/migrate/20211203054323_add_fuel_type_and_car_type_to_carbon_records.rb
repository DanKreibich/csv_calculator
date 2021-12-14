class AddFuelTypeAndCarTypeToCarbonRecords < ActiveRecord::Migration[6.0]
  def change
    add_column :carbon_records, :fuel_type, :string
    add_column :carbon_records, :car_type, :string
  end
end
