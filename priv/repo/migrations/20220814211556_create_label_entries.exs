defmodule Hyacinth.Repo.Migrations.CreateLabelEntries do
  use Ecto.Migration

  def change do
    create table(:label_entries) do
      add :label_value, :string, null: false

      add :element_id, references(:label_elements, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:label_entries, [:element_id])
  end
end
