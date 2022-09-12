defmodule Hyacinth.Warehouse.Object do
  use Hyacinth.Schema

  alias Hyacinth.Warehouse.{Object, DatasetObject}

  schema "objects" do
    field :hash, :string
    field :type, Ecto.Enum, values: [:blob, :tree]

    field :name, :string
    field :file_type, Ecto.Enum, values: [:png, :dicom, :nifti]

    belongs_to :parent_tree, Object

    has_many :children, Object, foreign_key: :parent_tree_id

    has_many :dataset_objects, DatasetObject
    has_many :datasets, through: [:dataset_objects, :dataset]

    timestamps()
  end
end
