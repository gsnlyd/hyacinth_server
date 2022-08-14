defmodule Hyacinth.Warehouse.Object do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.{Dataset, Object}

  schema "objects" do
    field :path, :string
    field :type, :string

    belongs_to :dataset, Dataset
    belongs_to :parent, Object

    timestamps()
  end

  @doc false
  def changeset(object, attrs) do
    object
    |> cast(attrs, [:path, :type, :dataset_id, :parent_id])
    |> validate_required([:path, :type, :dataset_id])
  end
end
