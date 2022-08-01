defmodule Hyacinth.Repo.Migrations.CreateDatasets do
  use Ecto.Migration

  def change do
    create table(:datasets) do
      add :name, :string
      add :dataset_type, :string
      add :parent_dataset_id, references(:datasets, on_delete: :nothing)
      add :created_by_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:datasets, [:parent_dataset_id])
    create index(:datasets, [:created_by_user_id])
  end
end
