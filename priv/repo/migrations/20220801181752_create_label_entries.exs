defmodule Hyacinth.Repo.Migrations.CreateLabelEntries do
  use Ecto.Migration

  def change do
    create table(:label_entries) do
      add :value, :string, null: false

      add :job_id, references(:label_jobs, on_delete: :restrict, on_update: :restrict), null: false
      add :element_id, references(:elements, on_delete: :restrict, on_update: :restrict), null: false
      add :created_by_user_id, references(:users, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:label_entries, [:job_id])
    create index(:label_entries, [:element_id])
    create index(:label_entries, [:created_by_user_id])
  end
end
