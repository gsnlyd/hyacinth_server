defmodule Hyacinth.Repo.Migrations.CreateDatasets do
  use Ecto.Migration

  def change do
    create table(:datasets) do
      add :name, :string, null: false
      add :type, :string, null: false

      timestamps()
    end
  end
end
