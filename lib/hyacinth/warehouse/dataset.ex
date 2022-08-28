defmodule Hyacinth.Warehouse.Dataset do
  use Hyacinth.Schema

  alias Hyacinth.Warehouse.DatasetObject

  schema "datasets" do
    field :name, :string
    field :type, Ecto.Enum, values: [:root, :derived]

    has_many :dataset_objects, DatasetObject
    has_many :objects, through: [:dataset_objects, :object]

    timestamps()
  end
end
