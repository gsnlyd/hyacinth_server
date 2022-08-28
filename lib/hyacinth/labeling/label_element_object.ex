defmodule Hyacinth.Labeling.LabelElementObject do
  use Hyacinth.Schema

  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.LabelElement

  schema "label_elements_objects" do
    field :object_index, :integer

    belongs_to :label_element, LabelElement
    belongs_to :object, Object

    timestamps()
  end
end
