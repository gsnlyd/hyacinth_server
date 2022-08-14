defmodule Hyacinth.Labeling.LabelElement do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Labeling.{LabelSession, LabelElementObject}

  schema "label_elements" do

    belongs_to :session, LabelSession

    # Join through label_elements_objects table
    has_many :label_element_objects, LabelElementObject, preload_order: [asc: :object_index]
    has_many :objects, through: [:label_element_objects, :object]

    timestamps()
  end

  @doc false
  def changeset(label_element, attrs) do
    label_element
    |> cast(attrs, [])
    |> validate_required([])
  end
end
