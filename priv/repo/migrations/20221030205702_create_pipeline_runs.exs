defmodule Hyacinth.Repo.Migrations.CreatePipelineRuns do
  use Ecto.Migration

  def change do
    create table(:pipeline_runs) do
      add :status, :string
      add :completed_at, :utc_datetime_usec
      add :ran_by_id, references(:users, on_delete: :nothing)
      add :pipeline_id, references(:pipelines, on_delete: :nothing)

      timestamps()
    end

    create index(:pipeline_runs, [:ran_by_id])
    create index(:pipeline_runs, [:pipeline_id])
  end
end
