defmodule Hyacinth.WarehouseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Warehouse` context.
  """

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.{Dataset}

  @doc """
  Generate a dataset.
  """
  def dataset_fixture(attrs \\ %{}) do
    {:ok, dataset} =
      attrs
      |> Enum.into(%{
        dataset_type: :root,
        name: "some name"
      })
      |> Hyacinth.Warehouse.create_dataset()

    dataset
  end

  @doc """
  Generate a root dataset with elements.
  """
  def root_dataset_fixture(name \\ nil, num_elements \\ 3) do
    name = if name != nil, do: name, else: "Dataset #{System.unique_integer()}"
    element_paths = Enum.map(1..num_elements, fn i -> "/tmp/some/path/element#{i}.png" end)

    {:ok, %{dataset: %Dataset{} = dataset}} = Warehouse.create_root_dataset(name, element_paths)
    dataset
  end

  @doc """
  Generate a element.
  """
  def element_fixture(attrs \\ %{}) do
    {:ok, element} =
      attrs
      |> Enum.into(%{
        element_type: "some element_type",
        path: "some path"
      })
      |> Hyacinth.Warehouse.create_element()

    element
  end
end
