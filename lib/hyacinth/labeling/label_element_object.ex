defmodule Hyacinth.Labeling.LabelElementObject do
  use Ecto.Schema
  import Ecto.Changeset

  schema "label_elements_objects" do
    field :object_index, :integer
    field :label_element_id, :id
    field :object_id, :id

    timestamps()
  end

  @doc false
  def changeset(label_element_object, attrs) do
    label_element_object
    |> cast(attrs, [:object_index])
    |> validate_required([:object_index])
  end
end
