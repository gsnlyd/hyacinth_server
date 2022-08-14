defmodule Hyacinth.Labeling.LabelElementObject do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.LabelElement

  schema "label_elements_objects" do
    field :object_index, :integer

    belongs_to :label_element, LabelElement
    belongs_to :object, Object

    timestamps()
  end

  @doc false
  def changeset(label_element_object, attrs) do
    label_element_object
    |> cast(attrs, [:object_index])
    |> validate_required([:object_index])
  end
end
