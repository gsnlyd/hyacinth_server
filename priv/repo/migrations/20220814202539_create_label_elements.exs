defmodule Hyacinth.Repo.Migrations.CreateLabelElements do
  use Ecto.Migration

  def change do
    create table(:label_elements) do
      add :session_id, references(:label_sessions, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:label_elements, [:session_id])
  end
end
