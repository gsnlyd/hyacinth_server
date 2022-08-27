defmodule Hyacinth.Warehouse.DatasetObject do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dataset_objects" do

    field :dataset_id, :id
    field :object_id, :id

    timestamps()
  end

  @doc false
  def changeset(dataset_object, attrs) do
    dataset_object
    |> cast(attrs, [])
    |> validate_required([])
  end
end
