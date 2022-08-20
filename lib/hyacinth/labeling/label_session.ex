defmodule Hyacinth.Labeling.LabelSession do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Accounts.User
  alias Hyacinth.Labeling.{LabelJob, LabelElement}

  schema "label_sessions" do
    field :blueprint, :boolean, default: false

    belongs_to :job, LabelJob
    belongs_to :user, User

    has_many :elements, LabelElement, foreign_key: :session_id

    timestamps()
  end

  @doc false
  def changeset(label_session, attrs) do
    label_session
    |> cast(attrs, [:blueprint])
    |> validate_required([:blueprint])
  end
end
