defmodule Hyacinth.Labeling.LabelEntry do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Labeling.LabelElement

  schema "label_entries" do
    field :label_value, :string

    belongs_to :element, LabelElement

    timestamps()
  end

  @doc false
  def changeset(label_entry, attrs) do
    label_entry
    |> cast(attrs, [:label_value])
    |> validate_required([:label_value])
  end
end
