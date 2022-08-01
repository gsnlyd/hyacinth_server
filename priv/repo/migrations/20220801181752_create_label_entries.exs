defmodule Hyacinth.Repo.Migrations.CreateLabelEntries do
  use Ecto.Migration

  def change do
    create table(:label_entries) do
      add :value, :string
      add :job_id, references(:labeling_jobs, on_delete: :nothing)
      add :element_id, references(:elements, on_delete: :nothing)
      add :created_by_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:label_entries, [:job_id])
    create index(:label_entries, [:element_id])
    create index(:label_entries, [:created_by_user_id])
  end
end
