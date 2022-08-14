defmodule Hyacinth.Repo.Migrations.CreateLabelElementsObjects do
  use Ecto.Migration

  def change do
    create table(:label_elements_objects) do
      add :object_index, :integer, null: false

      add :label_element_id, references(:label_elements, on_delete: :restrict, on_update: :restrict), null: false
      add :object_id, references(:objects, on_delete: :restrict, on_update: :restrict), null: false

      timestamps()
    end

    create index(:label_elements_objects, [:label_element_id])
    create index(:label_elements_objects, [:object_id])
  end
end
