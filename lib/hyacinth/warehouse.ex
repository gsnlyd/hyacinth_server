defmodule Hyacinth.Warehouse do
  @moduledoc """
  The Warehouse context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Hyacinth.Repo
  alias Hyacinth.Warehouse.{Dataset, Object, DatasetObject}

  @type object_tuple :: {String.t, String.t}
  @type parent_tuple :: {String.t, String.t, [object_tuple]}

  @doc """
  Returns the list of datasets.

  ## Examples

      iex> list_datasets()
      [%Dataset{}, ...]

  """
  def list_datasets do
    Repo.all(Dataset)
  end

  @doc """
  Gets a single dataset.

  Raises `Ecto.NoResultsError` if the Dataset does not exist.

  ## Examples

      iex> get_dataset!(123)
      %Dataset{}

      iex> get_dataset!(456)
      ** (Ecto.NoResultsError)

  """
  def get_dataset!(id), do: Repo.get!(Dataset, id)

  @doc """
  Creates a root dataset (a dataset with no parent).
  """
  @spec create_dataset(%{atom => term}, [map] | [%Object{}]) :: any
  def create_dataset(params, objects_or_params) when is_map(params) and is_list(objects_or_params) do
    Multi.new()
    |> Multi.insert(:dataset, Dataset.create_changeset(%Dataset{}, params))
    |> Multi.run(:objects, fn _repo, _values ->
      objects =
        case objects_or_params do
          # Re-use existing objects
          [%Object{} | _] ->
            objects_or_params

          # Create new objects (note: object params can contain nested child params)
          [%{} | _] ->
            Enum.map(objects_or_params, fn params ->
              Repo.insert! Object.create_changeset(%Object{}, params)
            end)
        end
      {:ok, objects}
    end)
    |> Multi.run(:dataset_objects, fn _repo, %{dataset: %Dataset{} = dataset, objects: objects} ->
      dataset_objects =
        objects
        |> Enum.map(fn %Object{} = object -> %DatasetObject{dataset_id: dataset.id, object_id: object.id} end)
        |> Enum.map(&Repo.insert/1)

      {:ok, dataset_objects}
    end)
    |> Repo.transaction()
  end



  @doc """
  Lists all objects which belong to the given dataset.
  """
  def list_objects(%Dataset{} = dataset) do
    Repo.all(
      from o in Ecto.assoc(dataset, :objects),
      select: o,
      preload: :children
    )
  end

  @doc """
  Gets a single Object.

  Raises `Ecto.NoResultsError` if the Object does not exist.

  ## Examples

      iex> get_object!(123)
      %Object{}

      iex> get_object!(456)
      ** (Ecto.NoResultsError)

  """
  def get_object!(id), do: Repo.get!(Object, id)
end
