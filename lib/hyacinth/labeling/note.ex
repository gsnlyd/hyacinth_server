defmodule Hyacinth.Labeling.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :text, :string
    field :element_id, :id

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
