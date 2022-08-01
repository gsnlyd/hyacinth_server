defmodule Hyacinth.Repo.Migrations.CreateLabelJobs do
  use Ecto.Migration

  def change do
    create table(:label_jobs) do
      add :name, :string
      add :label_type, :string
      add :dataset_id, references(:datasets, on_delete: :nothing)
      add :created_by_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:label_jobs, [:dataset_id])
    create index(:label_jobs, [:created_by_user_id])
  end
end
