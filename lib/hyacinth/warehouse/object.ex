defmodule Hyacinth.Warehouse.Object do
  use Hyacinth.Schema

  alias Hyacinth.Warehouse.{Object, DatasetObject}

  schema "objects" do
    field :hash, :string
    field :type, Ecto.Enum, values: [:blob, :tree]

    field :name, :string
    field :file_type, Ecto.Enum, values: [:png, :dicom]

    belongs_to :parent, Object

    has_many :dataset_objects, DatasetObject
    has_many :datasets, through: [:dataset_objects, :dataset]

    timestamps()
  end
end
