defmodule Hyacinth.Repo.Migrations.CreateObjects do
  use Ecto.Migration

  def change do
    create table(:objects) do
      add :path, :string, null: false
      add :type, :string, null: false

      add :dataset_id, references(:datasets, on_delete: :restrict, on_update: :restrict), null: false
      add :parent_id, references(:objects, on_delete: :restrict, on_update: :restrict)

      timestamps()
    end

    create index(:objects, [:dataset_id])
    create index(:objects, [:parent_id])
  end
end
