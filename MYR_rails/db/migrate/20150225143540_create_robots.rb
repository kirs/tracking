class CreateRobots < ActiveRecord::Migration
  def change
    create_table :robots do |t|
      t.string :name
      t.string :category
      t.integer :team_id, :null =>false
      t.integer :tracker_id

      t.timestamps null: false
    end
  end
end
