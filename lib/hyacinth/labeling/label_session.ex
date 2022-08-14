defmodule Hyacinth.Labeling.LabelSession do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Accounts.User
  alias Hyacinth.Labeling.LabelJob

  schema "label_sessions" do
    field :blueprint, :boolean, default: false

    belongs_to :job, LabelJob
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(label_session, attrs) do
    label_session
    |> cast(attrs, [:blueprint])
    |> validate_required([:blueprint])
  end
end
