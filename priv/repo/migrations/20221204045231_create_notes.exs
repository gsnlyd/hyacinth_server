defmodule Hyacinth.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :text, :string
      add :element_id, references(:label_elements, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create unique_index(:notes, [:element_id])
  end
end
