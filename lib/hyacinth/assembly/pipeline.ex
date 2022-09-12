defmodule Hyacinth.Assembly.Pipeline do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Accounts.User
  alias Hyacinth.Assembly.Transform

  schema "pipelines" do
    field :name, :string

    field :dataset_id, :integer, virtual: true

    belongs_to :creator, User

    has_many :transforms, Transform

    timestamps()
  end

  @doc false
  def changeset(pipeline, attrs) do
    pipeline
    |> cast(attrs, [:name, :dataset_id])
    |> validate_required([:name, :dataset_id])
    |> validate_length(:name, min: 1, max: 10)
  end
end
