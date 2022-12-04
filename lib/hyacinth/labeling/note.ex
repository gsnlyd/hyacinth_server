defmodule Hyacinth.Labeling.Note do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Labeling.LabelElement

  schema "notes" do
    field :text, :string

    belongs_to :element, LabelElement

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
