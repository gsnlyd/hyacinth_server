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
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

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
  def create_pipeline(%User{} = user, name, dataset_id, transform_changesets) when is_binary(name) and is_list(transform_changesets) do
    Multi.new()
    |> Multi.insert(:pipeline, %Pipeline{name: name, creator_id: user.id})
    |> Multi.run(:dataset, fn _repo, _changes ->
      dataset = Warehouse.get_dataset!(dataset_id)
      {:ok, dataset}
    end)
    |> Multi.run(:transforms, fn _repo, %{pipeline: %Pipeline{} = pipeline, dataset: %Dataset{} = dataset} ->
      transforms =
        transform_changesets
        |> Enum.with_index()
        |> Enum.map(fn {{transform_cs, options_cs}, i} ->
          driver = Ecto.Changeset.get_field(transform_cs, :driver)
          options =
            options_cs
            |> Ecto.Changeset.apply_action!(:insert)
            |> Map.from_struct()

          # Set input of first transform to dataset
          input_id = if i == 0, do: dataset.id, else: nil

          Repo.insert! %Transform{order_index: i, driver: driver, arguments: options, pipeline_id: pipeline.id, input_id: input_id}
        end)

      {:ok, transforms}
    end)
    |> Multi.run(:sanity_validate_transform_options, fn _repo, %{transforms: transforms} ->
      valid = Enum.all?(transforms, fn %Transform{} = transform ->
        %Ecto.Changeset{} = changeset = Driver.options_changeset(transform.driver, transform.arguments)
        changeset.valid?
      end)

      if valid do
        {:ok, true}
      else
        {:error, false}
      end
    end)
    |> Repo.transaction()
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
    |> Multi.run(:transform, fn _repo, _changes ->
      # Refresh transform within transaction
      {:ok, Repo.get!(Transform, transform.id)}
    end)
    |> Multi.run(:validate_transform_has_no_output, fn _repo, %{transform: %Transform{} = transform} ->
      if transform.output_id == nil do
        {:ok, true}
      else
        {:error, false}
      end
    end)
    |> Multi.run(:dataset, fn _repo, %{transform: %Transform{} = transform} ->
      dataset_params = %{name: "Derived from pipeline #{transform.pipeline_id} transform no #{transform.order_index}", type: :derived}
      {:ok, %{dataset: dataset}} = Warehouse.create_dataset(dataset_params, objects_or_params)
      {:ok, dataset}
    end)
    |> Multi.run(:updated_transform, fn _repo, %{transform: %Transform{} = transform, dataset: %Dataset{} = dataset} ->
      %Transform{} = updated_transform = Repo.update! Ecto.Changeset.change(transform, %{output_id: dataset.id})
      {:ok, updated_transform}
    end)
    |> Multi.run(:updated_next_transform, fn _repo, %{updated_transform: %Transform{} = transform} ->
      next_transform = Repo.one(
        from t in Transform,
        where: t.pipeline_id == ^transform.pipeline_id and t.order_index == ^transform.order_index + 1,
        select: t
      )

      if next_transform do
        next_transform = Repo.update! Ecto.Changeset.change(next_transform, %{input_id: transform.output_id})
        {:ok, next_transform}
      else
        {:ok, nil}
      end
    end)
    |> Repo.transaction()
  end
end
