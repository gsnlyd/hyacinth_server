defmodule Hyacinth.Warehouse.DatasetObject do
  use Hyacinth.Schema

  alias Hyacinth.Warehouse.{Dataset, Object}

  schema "dataset_objects" do
    belongs_to :dataset, Dataset
    belongs_to :object, Object

    timestamps()
  end
end
