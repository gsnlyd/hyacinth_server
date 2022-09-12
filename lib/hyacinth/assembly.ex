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
  alias Hyacinth.Warehouse.Dataset
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
  def complete_transform(%Transform{} = transform, object_tuples) do
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
    |> Multi.run(:dataset, fn _repo, _changes ->
      # TODO: create a derived dataset instead, properly
      {:ok, %{dataset: dataset}} = Warehouse.create_root_dataset("dataset output", :png, object_tuples)
      {:ok, dataset}
    end)
    |> Multi.run(:update_transform, fn _repo, %{transform: %Transform{} = transform, dataset: %Dataset{} = dataset} ->
      %Transform{} = updated_transform = Repo.update! Ecto.Changeset.change(transform, %{output_id: dataset.id})
      {:ok, updated_transform}
    end)
    |> Repo.transaction()
  end
end
