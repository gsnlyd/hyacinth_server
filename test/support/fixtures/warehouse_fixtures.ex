defmodule Hyacinth.WarehouseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Warehouse` context.
  """

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.{Dataset}

  @doc """
  Generate a root dataset with objects.
  """
  def root_dataset_fixture(name \\ nil, num_objects \\ 3) do
    name = if name != nil, do: name, else: "Dataset #{System.unique_integer()}"
    object_paths = Enum.map(1..num_objects, fn i -> "/tmp/some/path/object#{i}.png" end)

    {:ok, %{dataset: %Dataset{} = dataset}} = Warehouse.create_root_dataset(name, object_paths)
    dataset
  end
end
