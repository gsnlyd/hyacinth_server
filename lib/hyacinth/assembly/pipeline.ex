defmodule Hyacinth.Assembly.Pipeline do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pipelines" do
    field :name, :string
    field :creator_id, :id

    timestamps()
  end

  @doc false
  def changeset(pipeline, attrs) do
    pipeline
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
