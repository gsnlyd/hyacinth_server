defmodule Hyacinth.Repo.Migrations.CreateElements do
  use Ecto.Migration

  def change do
    create table(:elements) do
      add :path, :string
      add :element_type, :string
      add :dataset_id, references(:datasets, on_delete: :nothing)
      add :parent_element_id, references(:elements, on_delete: :nothing)
      add :created_by_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:elements, [:dataset_id])
    create index(:elements, [:parent_element_id])
    create index(:elements, [:created_by_user_id])
  end
end
