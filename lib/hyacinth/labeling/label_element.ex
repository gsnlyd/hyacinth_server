defmodule Hyacinth.Labeling.LabelElement do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Labeling.{LabelSession, LabelElementObject, LabelEntry}

  schema "label_elements" do
    field :element_index, :integer
    field :notes, :string

    belongs_to :session, LabelSession

    # Join through label_elements_objects table
    has_many :label_element_objects, LabelElementObject, preload_order: [asc: :object_index]
    has_many :objects, through: [:label_element_objects, :object]

    has_many :labels, LabelEntry, foreign_key: :element_id, preload_order: [desc: :inserted_at]

    timestamps()
  end

  @doc false
  def update_notes_changeset(label_element, attrs) do
    label_element
    |> cast(attrs, [:notes])
    |> validate_length(:notes, max: 1000)
  end
end
