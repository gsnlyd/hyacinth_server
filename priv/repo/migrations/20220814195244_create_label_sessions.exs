defmodule Hyacinth.Repo.Migrations.CreateLabelSessions do
  use Ecto.Migration

  def change do
    create table(:label_sessions) do
      add :blueprint, :boolean, default: false, null: false

      add :job_id, references(:label_jobs, on_delete: :restrict, on_update: :restrict), null: false
      add :user_id, references(:users, on_delete: :restrict, on_update: :restrict)

      timestamps()
    end

    create index(:label_sessions, [:job_id])
    create index(:label_sessions, [:user_id])
  end
end
