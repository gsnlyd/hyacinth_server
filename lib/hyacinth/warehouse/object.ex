defmodule Hyacinth.Warehouse.Object do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.{Object, DatasetObject}

  schema "objects" do
    field :path, :string
    field :type, :string

    belongs_to :parent, Object

    has_many :dataset_objects, DatasetObject
    has_many :datasets, through: [:dataset_objects, :dataset]

    timestamps()
  end

  @doc false
  def changeset(object, attrs) do
    object
    |> cast(attrs, [:path, :type, :parent_id])
    |> validate_required([:path, :type])
  end
end
