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
  Returns an `Ecto.Changeset` for tracking Transform changes.

  ## Examples

      iex> change_transform(transform)
      %Ecto.Changeset{data: %Transform{}}

  """
  def change_transform(%Transform{} = transform, attrs \\ %{}) do
    Transform.changeset(transform, attrs)
  end
end
