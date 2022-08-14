defmodule Hyacinth.Labeling.LabelElement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "label_elements" do

    field :session_id, :id

    timestamps()
  end

  @doc false
  def changeset(label_element, attrs) do
    label_element
    |> cast(attrs, [])
    |> validate_required([])
  end
end
