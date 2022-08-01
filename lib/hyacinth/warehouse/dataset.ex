defmodule Hyacinth.Warehouse.Dataset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "datasets" do
    field :dataset_type, Ecto.Enum, values: [:root, :derived]
    field :name, :string
    field :parent_dataset_id, :id
    field :created_by_user_id, :id

    timestamps()
  end

  @doc false
  def changeset(dataset, attrs) do
    dataset
    |> cast(attrs, [:name, :dataset_type])
    |> validate_required([:name, :dataset_type])
  end
end
