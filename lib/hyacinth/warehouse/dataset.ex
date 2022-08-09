defmodule Hyacinth.Warehouse.Dataset do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Accounts.User

  schema "datasets" do
    field :name, :string
    field :dataset_type, Ecto.Enum, values: [:root, :derived]

    belongs_to :parent_dataset, Dataset
    belongs_to :created_by_user, User

    timestamps()
  end

  @doc false
  def changeset(dataset, attrs) do
    dataset
    |> cast(attrs, [:name, :dataset_type])
    |> validate_required([:name, :dataset_type])
  end
end
