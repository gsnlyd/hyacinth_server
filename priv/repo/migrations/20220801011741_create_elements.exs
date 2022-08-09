defmodule Hyacinth.Repo.Migrations.CreateElements do
  use Ecto.Migration

  def change do
    create table(:elements) do
      add :path, :string, null: false
      add :element_type, :string, null: false

      add :dataset_id, references(:datasets, on_delete: :restrict, on_update: :restrict), null: false
      add :parent_element_id, references(:elements, on_delete: :restrict, on_update: :restrict)

      timestamps()
    end

    create index(:elements, [:dataset_id])
    create index(:elements, [:parent_element_id])
  end
end
