defmodule Hyacinth.Repo.Migrations.CreateTransformRuns do
  use Ecto.Migration

  def change do
    create table(:transform_runs) do
      add :order_index, :integer, null: false
      add :status, :string, null: false

      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec

      add :input_id, references(:datasets, on_delete: :restrict, on_update: :restrict)
      add :output_id, references(:datasets, on_delete: :restrict, on_update: :restrict)

      add :pipeline_run_id, references(:pipeline_runs, on_delete: :restrict, on_update: :restrict), null: false
      add :transform_id, references(:transforms, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:transform_runs, [:input_id])
    create index(:transform_runs, [:output_id])
    create index(:transform_runs, [:pipeline_run_id])
    create index(:transform_runs, [:transform_id])
  end
end
