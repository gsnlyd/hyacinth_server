defmodule Hyacinth.Labeling.LabelEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "label_entries" do
    field :label_value, :string
    field :element_id, :id

    timestamps()
  end

  @doc false
  def changeset(label_entry, attrs) do
    label_entry
    |> cast(attrs, [:label_value])
    |> validate_required([:label_value])
  end
end
