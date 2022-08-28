defmodule Hyacinth.Labeling.LabelSession do
  use Hyacinth.Schema

  alias Hyacinth.Accounts.User
  alias Hyacinth.Labeling.{LabelJob, LabelElement}

  schema "label_sessions" do
    field :blueprint, :boolean, default: false

    belongs_to :job, LabelJob
    belongs_to :user, User

    has_many :elements, LabelElement, foreign_key: :session_id

    timestamps()
  end
end
