defmodule Hyacinth.WarehouseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Warehouse` context.
  """

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.{Dataset, FormatType}

  @hash_fixture_algorithm :sha256

  @doc """
  Generates a hash string fixture by hashing
  the given data.

  ## Examples

      iex> hash_fixture("hello world")
      "sha256:..."

  """
  @spec hash_fixture(String.t) :: String.t
  def hash_fixture(data) when is_binary(data) do
    hash = :crypto.hash(@hash_fixture_algorithm, data)
    Atom.to_string(@hash_fixture_algorithm) <> ":" <> Base.encode16(hash, case: :lower)
  end

  @doc """
  Generates a params map for an object.

  ## Examples

      iex> object_params_fixture("my_object", :png)
      %{
        hash: ...,
        type: :blob,
        name: "my_object.png",
        file_type: :png
      }

  """
  @spec object_params_fixture(String.t, atom) :: map
  def object_params_fixture(name \\ "object", type \\ :png) do
    %{
      hash: hash_fixture(name),
      type: :blob,
      name: name <> FormatType.extension(type),
      file_type: type,
    }
  end

  @doc """
  Generates many maps of object params.

  See `object_params_fixture/2`.

  ## Examples

      iex> many_object_params_fixtures(3, "my_object", :png)
      [
        %{hash: ..., type: :blob, name: "my_object1.png", file_type: :png},
        %{hash: ..., type: :blob, name: "my_object2.png", file_type: :png},
        %{hash: ..., type: :blob, name: "my_object3.png", file_type: :png},
      ]

  """
  @spec many_object_params_fixtures(integer, String.t, atom) :: [map]
  def many_object_params_fixtures(count \\ 3, name_prefix \\ "object", type \\ :png) do
    Enum.map(1..count, fn i ->
      object_params_fixture(name_prefix <> Integer.to_string(i), type)
    end)
  end

  @doc """
  Generate a root dataset with 3 objects.

  ## Examples

      iex> root_dataset_fixture("Some Name", 3)
      %Dataset{name: "Some Name", ...}

  """
  @spec root_dataset_fixture(String.t | nil, integer) :: %Dataset{}
  def root_dataset_fixture(name \\ nil, num_objects \\ 3) do
    dataset_params = %{
      name: name || "Dataset #{System.unique_integer()}",
      type: :root,
    }
    object_params = many_object_params_fixtures(num_objects)

    {:ok, %{dataset: %Dataset{} = dataset}} = Warehouse.create_dataset(dataset_params, object_params)
    dataset
  end
end
