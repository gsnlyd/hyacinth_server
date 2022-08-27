defmodule Hyacinth.Warehouse.DatasetObject do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.{Dataset, Object}

  schema "dataset_objects" do
    belongs_to :dataset, Dataset
    belongs_to :object, Object

    timestamps()
  end

  @doc false
  def changeset(dataset_object, attrs) do
    dataset_object
    |> cast(attrs, [])
    |> validate_required([])
  end
end
