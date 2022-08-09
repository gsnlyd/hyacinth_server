defmodule Hyacinth.Warehouse do
  @moduledoc """
  The Warehouse context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Hyacinth.Repo
  alias Hyacinth.Warehouse.{Dataset, Element}

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
  Creates a dataset.

  ## Examples

      iex> create_dataset(%{field: value})
      {:ok, %Dataset{}}

      iex> create_dataset(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_dataset(attrs \\ %{}) do
    %Dataset{}
    |> Dataset.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a root dataset (a dataset with no parent).
  """
  def create_root_dataset(name, element_paths) when is_binary(name) and is_list(element_paths) do
    Multi.new()
    |> Multi.insert(:dataset, %Dataset{name: name, dataset_type: :root})
    |> Multi.run(:elements, fn _repo, %{dataset: %Dataset{} = dataset} ->
      elements =
        element_paths
        |> Enum.map(fn path -> %Element{path: path, element_type: "png", dataset_id: dataset.id} end)
        |> Enum.map(&Repo.insert!/1)

      {:ok, elements}
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a dataset.

  ## Examples

      iex> update_dataset(dataset, %{field: new_value})
      {:ok, %Dataset{}}

      iex> update_dataset(dataset, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_dataset(%Dataset{} = dataset, attrs) do
    dataset
    |> Dataset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a dataset.

  ## Examples

      iex> delete_dataset(dataset)
      {:ok, %Dataset{}}

      iex> delete_dataset(dataset)
      {:error, %Ecto.Changeset{}}

  """
  def delete_dataset(%Dataset{} = dataset) do
    Repo.delete(dataset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dataset changes.

  ## Examples

      iex> change_dataset(dataset)
      %Ecto.Changeset{data: %Dataset{}}

  """
  def change_dataset(%Dataset{} = dataset, attrs \\ %{}) do
    Dataset.changeset(dataset, attrs)
  end



  @doc """
  Lists all elements for a dataset.
  """
  def list_dataset_elements(dataset_id) do
    Repo.all(
      from e in Element,
      where: e.dataset_id == ^dataset_id,
      order_by: e.id
    )
  end

  @doc """
  Gets a single element.

  Raises `Ecto.NoResultsError` if the Element does not exist.

  ## Examples

      iex> get_element!(123)
      %Element{}

      iex> get_element!(456)
      ** (Ecto.NoResultsError)

  """
  def get_element!(id), do: Repo.get!(Element, id)
end
