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
  Returns the list of datasets which have
  at least one object with the given format.

  ## Examples

      iex> list_datasets_with_format(:png)
      [%Dataset{}, %Dataset{}, ...]

  """
  @spec list_datasets_with_format(atom) :: [%Dataset{}]
  def list_datasets_with_format(format) when is_atom(format) do
    Repo.all(
      from d in Dataset,
      inner_join: o in assoc(d, :objects),
      where: o.format == ^format,
      select: d,
      distinct: true
    )
  end

  defmodule DatasetStats do
    @type t :: %__MODULE__{
      dataset: %Dataset{},
      num_objects: integer,
      num_jobs: integer,
    }
    @enforce_keys [:dataset, :num_objects, :num_jobs]
    defstruct @enforce_keys
  end

  @doc """
  Returns a list of all datasets along with
  the number of objects and jobs each has.

  ## Examples

      iex> list_datasets_with_stats()
      [
        %DatasetStats{dataset: %Dataset{...}, num_objects: 100, num_jobs: 0},
        %DatasetStats{dataset: %Dataset{...}, num_objects: 20, num_jobs: 2},
        %DatasetStats{dataset: %Dataset{...}, num_objects: 30, num_jobs: 10},
      ]

  """
  @spec list_datasets_with_stats() :: [%DatasetStats{}]
  def list_datasets_with_stats do
    Repo.all(
      from d in Dataset,
      left_join: dobj in assoc(d, :dataset_objects),
      left_join: lj in assoc(d, :jobs),
      group_by: d.id,
      select: %DatasetStats{dataset: d, num_objects: count(dobj.id, :distinct), num_jobs: count(lj.id, :distinct)}
    )
  end

  @doc """
  Gets a single dataset.

  Raises `Ecto.NoResultsError` if the dataset does not exist.

  ## Examples

      iex> get_dataset!(123)
      %Dataset{}

      iex> get_dataset!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_dataset!(term) :: %Dataset{}
  def get_dataset!(id), do: Repo.get!(Dataset, id)

  @doc """
  Gets stats for a single dataset.

  Raises `Ecto.NoResultsError` if the dataset does not exist.

  ## Examples

      iex> get_dataset_stats!(123)
      %DatasetStats{...}

      iex> get_dataset_stats!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_dataset_stats!(term) :: %DatasetStats{}
  def get_dataset_stats!(id) do
    Repo.one!(
      from d in Dataset,
      where: d.id == ^id,
      left_join: dobj in assoc(d, :dataset_objects),
      left_join: lj in assoc(d, :jobs),
      group_by: d.id,
      select: %DatasetStats{dataset: d, num_objects: count(dobj.id, :distinct), num_jobs: count(lj.id, :distinct)}
    )
  end

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
