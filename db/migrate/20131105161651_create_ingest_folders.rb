class CreateIngestFolders < ActiveRecord::Migration
  def change
    create_table :ingest_folders do |t|
      t.string :dirpath
      t.string :username
      t.string :admin_policy_pid
      t.string :collection_pid
      t.string :model
      t.boolean :add_parents
      t.integer :parent_id_length

      t.timestamps
    end
  end
end