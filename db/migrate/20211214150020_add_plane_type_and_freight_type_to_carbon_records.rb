class AddPlaneTypeAndFreightTypeToCarbonRecords < ActiveRecord::Migration[6.0]
  def change
    add_column :carbon_records, :plane_type, :string
    add_column :carbon_records, :freight_type, :string
  end
end
