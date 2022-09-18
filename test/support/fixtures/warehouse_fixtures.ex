defmodule Hyacinth.WarehouseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Warehouse` context.
  """

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.{Dataset}

  @hash_fixture_algorithm :sha256

  def hash_fixture(data) when is_binary(data) do
    hash = :crypto.hash(@hash_fixture_algorithm, data)
    Atom.to_string(@hash_fixture_algorithm) <> ":" <> Base.encode16(hash, case: :lower)
  end

  @doc """
  Generate a root dataset with objects.
  """
  def root_dataset_fixture(name \\ nil, num_objects \\ 3) do
    name = if name != nil, do: name, else: "Dataset #{System.unique_integer()}"

    params = %{name: name, type: :root}

    object_params = Enum.map(1..num_objects, fn i ->
      %{
        hash: hash_fixture("object#{i}"),
        type: :blob,
        name: "object#{i}.png",
        file_type: :png,
      }
    end)

    {:ok, %{dataset: %Dataset{} = dataset}} = Warehouse.create_dataset(params, object_params)
    dataset
  end
end
