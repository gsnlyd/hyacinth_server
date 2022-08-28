defmodule Hyacinth.Repo.Migrations.CreateTransforms do
  use Ecto.Migration

  def change do
    create table(:transforms) do
      add :order_index, :integer
      add :driver, :string
      add :arguments, :map
      add :pipeline_id, references(:pipelines, on_delete: :nothing)
      add :input_id, references(:datasets, on_delete: :nothing)
      add :output_id, references(:datasets, on_delete: :nothing)

      timestamps()
    end

    create index(:transforms, [:pipeline_id])
    create index(:transforms, [:input_id])
    create index(:transforms, [:output_id])
  end
end
