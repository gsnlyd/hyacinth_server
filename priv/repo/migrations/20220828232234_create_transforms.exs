defmodule Hyacinth.Repo.Migrations.CreateTransforms do
  use Ecto.Migration

  def change do
    create table(:transforms) do
      add :order_index, :integer
      add :driver, :string
      add :options, :map

      add :pipeline_id, references(:pipelines, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:transforms, [:pipeline_id])
  end
end
