class CreateCarbonRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :carbon_records do |t|
      t.string :customer_id
      t.string :calculation_type
      t.string :origin
      t.string :destination
      t.float :weight_in_tonnes
      t.string :specific_method

      t.timestamps
    end
  end
end
