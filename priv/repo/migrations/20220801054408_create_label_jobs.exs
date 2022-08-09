defmodule Hyacinth.Repo.Migrations.CreateLabelJobs do
  use Ecto.Migration

  def change do
    create table(:label_jobs) do
      add :name, :string, null: false
      add :label_type, :string, null: false

      add :dataset_id, references(:datasets, on_delete: :restrict, on_update: :restrict), null: false
      add :created_by_user_id, references(:users, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:label_jobs, [:dataset_id])
    create index(:label_jobs, [:created_by_user_id])
  end
end
