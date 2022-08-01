defmodule Hyacinth.Labeling.LabelEntry do
  use Hyacinth.Schema
  import Ecto.Changeset

  schema "label_entries" do
    field :value, :string
    field :job_id, :id
    field :element_id, :id
    field :created_by_user_id, :id

    timestamps()
  end

  @doc false
  def changeset(label_entry, attrs) do
    label_entry
    |> cast(attrs, [:value])
    |> validate_required([:value])
  end
end
