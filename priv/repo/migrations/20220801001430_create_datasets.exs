defmodule Hyacinth.Repo.Migrations.CreateDatasets do
  use Ecto.Migration

  def change do
    create table(:datasets) do
      add :name, :string, null: false
      add :dataset_type, :string, null: false

      add :parent_dataset_id, references(:datasets, on_delete: :restrict, on_update: :restrict)
      add :created_by_user_id, references(:users, on_delete: :restrict, on_update: :restrict)

      timestamps()
    end

    create index(:datasets, [:parent_dataset_id])
    create index(:datasets, [:created_by_user_id])
  end
end
