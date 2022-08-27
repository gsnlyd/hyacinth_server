defmodule Hyacinth.Repo.Migrations.CreateDatasetObjects do
  use Ecto.Migration

  def change do
    create table(:dataset_objects) do
      add :dataset_id, references(:datasets, on_delete: :restrict, on_update: :restrict), null: false
      add :object_id, references(:objects, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:dataset_objects, [:dataset_id])
    create index(:dataset_objects, [:object_id])
  end
end
