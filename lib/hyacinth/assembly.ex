defmodule Hyacinth.Assembly do
  @moduledoc """
  The Assembly context defines functions for creating
  pipelines which transform datasets.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Hyacinth.Repo

  alias Hyacinth.Warehouse

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.{Dataset, Object}
  alias Hyacinth.Assembly.{Pipeline, Transform}

  @doc """
  Gets a single Pipeline.

  Raises `Ecto.NoResultsError` if the Pipeline does not exist.

  ## Examples
    
      get_pipeline!(123)
      %Pipeline{...}

      get_pipeline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pipeline!(id), do: Repo.get!(Pipeline, id)

  @doc """
  Creates a pipeline.

  ## Examples

      create_pipeline()
      {:ok, %Pipeline{...}}

  """
  @spec create_pipeline(%User{}, map | Keyword.t) :: {:ok, %Pipeline{}} | {:error, %Ecto.Changeset{}}
  def create_pipeline(%User{} = user, params) do
    Repo.insert Pipeline.changeset(%Pipeline{creator_id: user.id}, params)
  end

  @doc """
  Returns a list of all Transforms which belong to the given Pipeline.

  ## Examples

      list_transforms(%Pipeline{...})
      [%Transform{}, %Transform{}, ...]

  """
  def list_transforms(%Pipeline{} = pipeline) do
    Repo.all(
      from t in Ecto.assoc(pipeline, :transforms),
      select: t,
      preload: [:input, :output]
    )
  end

  @doc """
  Returns a single Transform with its input and output datasets
  preloaded.

  ## Examples

      iex> get_transform_with_datasets(123)
      %Transform{...}

      iex> get_transform_with_datasets(456)
      nil

  """
  @spec get_transform_with_datasets(id :: any) :: %Transform{}
  def get_transform_with_datasets(id) do
    Repo.one(
      from t in Transform,
      where: t.id == ^id,
      select: t,
      preload: [:input, :output]
    )
  end

  @doc """
  Returns an `Ecto.Changeset` for tracking Transform changes.

  ## Examples

      iex> change_transform(transform)
      %Ecto.Changeset{data: %Transform{}}

  """
  def change_transform(%Transform{} = transform, attrs \\ %{}) do
    Transform.changeset(transform, attrs)
  end

  @doc """
  Completes a Transform.
  """
  @spec complete_transform(%Transform{}, [%Object{}] | [map]) :: any
  def complete_transform(%Transform{} = transform, objects_or_params) do
    Multi.new()
    |> Multi.run(:validate_transform_has_no_output, fn _repo, _changes ->
      # Must be checked within transaction
      output_id = Repo.one! from(t in Transform, where: t.id == ^transform.id, select: t.output_id)
      case output_id do
        nil -> {:ok, output_id}
        _ -> {:error, output_id}
      end
    end)
    |> Multi.run(:dataset, fn _repo, _changes ->
      %Pipeline{} = pipeline = get_pipeline!(transform.pipeline_id)
      dataset_params = %{
        name: "Derived from #{pipeline.name} T#{transform.order_index + 1}",
        type: :derived,
      }
      {:ok, %{dataset: dataset}} = Warehouse.create_dataset(dataset_params, objects_or_params)
      {:ok, dataset}
    end)
    |> Multi.run(:update_transform_output, fn _repo, %{dataset: %Dataset{} = dataset} ->
      Repo.update Transform.update_output_changeset(transform, %{output_id: dataset.id})
    end)
    |> Multi.run(:update_next_transform_input, fn _repo, %{dataset: %Dataset{} = dataset} ->
      next_transform = Repo.one(
        from t in Transform,
        where: t.pipeline_id == ^transform.pipeline_id and t.order_index == ^transform.order_index + 1,
        select: t
      )

      case next_transform do
        %Transform{} ->
          Repo.update Transform.update_input_changeset(next_transform, %{input_id: dataset.id})

        nil ->
          {:ok, nil}
      end
    end)
    |> Repo.transaction()
  end
end
