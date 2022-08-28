defmodule Hyacinth.Warehouse.Dataset do
  use Hyacinth.Schema

  alias Hyacinth.Warehouse.{Dataset, DatasetObject}
  alias Hyacinth.Accounts.User

  schema "datasets" do
    field :name, :string
    field :dataset_type, Ecto.Enum, values: [:root, :derived]

    belongs_to :parent_dataset, Dataset
    belongs_to :created_by_user, User

    has_many :dataset_objects, DatasetObject
    has_many :objects, through: [:dataset_objects, :object]

    timestamps()
  end
end
