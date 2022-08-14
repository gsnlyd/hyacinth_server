defmodule Hyacinth.Labeling.LabelSession do
  use Ecto.Schema
  import Ecto.Changeset

  schema "label_sessions" do
    field :blueprint, :boolean, default: false
    field :user_id, :id
    field :job_id, :id

    timestamps()
  end

  @doc false
  def changeset(label_session, attrs) do
    label_session
    |> cast(attrs, [:blueprint])
    |> validate_required([:blueprint])
  end
end
