defmodule Hyacinth.Warehouse.Object do
  use Hyacinth.Schema

  alias Hyacinth.Warehouse.{Object, DatasetObject}

  schema "objects" do
    field :type, :string
    field :rel_path, :string
    field :hash, :string

    belongs_to :parent, Object

    has_many :dataset_objects, DatasetObject
    has_many :datasets, through: [:dataset_objects, :dataset]

    timestamps()
  end
end
