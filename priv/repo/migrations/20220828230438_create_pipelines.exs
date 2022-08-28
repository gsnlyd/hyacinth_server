defmodule Hyacinth.Repo.Migrations.CreatePipelines do
  use Ecto.Migration

  def change do
    create table(:pipelines) do
      add :name, :string

      add :creator_id, references(:users, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:pipelines, [:creator_id])
  end
end
