defmodule Hyacinth.WarehouseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Warehouse` context.
  """

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
