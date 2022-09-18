defmodule Hyacinth.Warehouse.Dataset do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.DatasetObject

  schema "datasets" do
    field :name, :string
    field :type, Ecto.Enum, values: [:root, :derived]

    has_many :dataset_objects, DatasetObject
    has_many :objects, through: [:dataset_objects, :object]

    timestamps()
  end

  @doc false
  def create_changeset(dataset, attrs) do
    dataset
    |> cast(attrs, [:name, :type])
    |> validate_required([:name, :type])
  end
end
