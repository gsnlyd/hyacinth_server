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
  alias Hyacinth.Assembly.{Pipeline, Transform, PipelineRun, TransformRun}

  @doc """
  Returns a list of all Pipelines with their
  relations preloaded.

  The following relations are preloaded:

    * creator
    * transforms

  ## Examples

      iex> list_pipelines_preloaded()
      [%Pipeline{}, %Pipeline{}, ...]

  """
  @spec list_pipelines_preloaded() :: [%Pipeline{}]
  def list_pipelines_preloaded do
    Repo.all(
      from p in Pipeline,
      preload: [:creator, :transforms]
    )
  end

  @doc """
  Gets a single Pipeline.

  Raises `Ecto.NoResultsError` if the Pipeline does not exist.

  ## Examples
    
      get_pipeline!(123)
      %Pipeline{...}

      get_pipeline!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_pipeline!(term) :: %Pipeline{}
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
  @spec list_transforms(%Pipeline{}) :: [%Transform{}]
  def list_transforms(%Pipeline{} = pipeline) do
    Repo.all(
      from t in Ecto.assoc(pipeline, :transforms),
      select: t
    )
  end

  @doc """
  Gets a single PipelineRun.

  The following attributes are preloaded:
    * `pipeline`
    * `transform_runs`
    * `TransformRun.input`
    * `TransformRun.output`

  """
  @spec get_pipeline_run!(term) :: %PipelineRun{}
  def get_pipeline_run!(id) do
    Repo.one!(
      from pr in PipelineRun,
      where: pr.id == ^id,
      select: pr,
      preload: [:pipeline, transform_runs: [:transform, :input, :output]]
    )
  end

  @doc """
  Creates a new PipelineRun for the given Pipeline.

  The `input` to the first TransformRun will be the given Dataset,
  and the `ran_by` of the PipelineRun will be the given User.

  ## Examples

    iex> create_pipeline_run!(some_pipeline, some_dataset, some_user)
    %PipelineRun{...}

  """
  @spec create_pipeline_run!(%Pipeline{}, %Dataset{}, %User{}) :: %PipelineRun{}
  def create_pipeline_run!(%Pipeline{} = pipeline, %Dataset{} = dataset, %User{} = user) do
    result =
      Multi.new()
      |> Multi.insert(:pipeline_run, %PipelineRun{status: :running, ran_by_id: user.id, pipeline_id: pipeline.id})
      |> Multi.run(:transform_runs, fn _repo, %{pipeline_run: %PipelineRun{} = pipeline_run} ->
        transform_runs =
          Enum.map(list_transforms(pipeline), fn %Transform{} = transform ->
            Repo.insert!(%TransformRun{
              order_index: transform.order_index,
              status: :waiting,
              input_id: if(transform.order_index == 0, do: dataset.id, else: nil),
              pipeline_run_id: pipeline_run.id,
              transform_id: transform.id,
            })
          end)
        {:ok, transform_runs}
      end)
      |> Repo.transaction()

    {:ok, %{pipeline_run: %PipelineRun{} = pipeline_run}} = result
    pipeline_run
  end

  @doc """
  Returns a list of all TransformRuns which belong to the given PipelineRun.

  ## Examples

      iex> list_transform_runs(some_pipeline_run)
      [%TransformRun{}, ...]

  """
  @spec list_transform_runs(%PipelineRun{}) :: [%TransformRun{}]
  def list_transform_runs(%PipelineRun{} = pipeline_run) do
    Repo.all(
      from tr in TransformRun,
      where: tr.pipeline_run_id == ^pipeline_run.id,
      select: tr,
      preload: [:input, :output, :pipeline_run, :transform]
    )
  end

  @doc """
  Gets a single TransformRun.

  The following fields are preloaded:
    * input
    * output
    * transform

  ## Examples

      iex> get_transform_run!(123)
      %TransformRun{...}

      iex> get_transform_run!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_transform_run!(term) :: %TransformRun{}
  def get_transform_run!(id) do
    Repo.one!(
      from tr in TransformRun,
      where: tr.id == ^id,
      select: tr,
      preload: [:input, :output, :transform]
    )
  end

  @doc """
  Starts a TransformRun.

  Updates the `status` and `started_at` fields of
  the TransformRun.

  Fails if transform is not `:waiting`, pipeline is not `:running`,
  or previous transforms are not `:complete`.

  ## Examples

      iex> start_transform_run!(some_transform_run)
      {:ok, _changes}

      iex> start_transform_run!(invalid_transform_run)
      {:error, _failed_operation, _value, _changes}

  """
  @spec start_transform_run!(%TransformRun{}) :: {:ok, map} | {:error, atom, term, map}
  def start_transform_run!(%TransformRun{} = transform_run) do
    Multi.new()
    |> Multi.run(:validate_transform_waiting, fn _repo, _changes ->
      case get_transform_run!(transform_run.id).status do
        :waiting -> {:ok, :waiting}
        status -> {:error, status}
      end
    end)
    |> Multi.run(:pipeline_run, fn _repo, _changes ->
      {:ok, get_pipeline_run!(transform_run.pipeline_run_id)}
    end)
    |> Multi.run(:validate_pipeline_running, fn _repo, %{pipeline_run: %PipelineRun{} = pipeline_run} ->
      case pipeline_run.status do
        :running -> {:ok, :running}
        status -> {:error, status}
      end
    end)
    |> Multi.run(:validate_previous_transforms_complete, fn _repo, %{pipeline_run: %PipelineRun{} = pipeline_run} ->
      all_complete =
        pipeline_run.transform_runs
        |> Enum.slice(0, transform_run.order_index)
        |> Enum.all?(fn %TransformRun{} = tr -> tr.status == :complete end)

      if all_complete do
        {:ok, True}
      else
        {:error, False}
      end
    end)
    |> Multi.run(:update_transform_run, fn _repo, _changes ->
      updated_params = %{
        status: :running,
        started_at: DateTime.utc_now(),
      }
      Repo.update Ecto.Changeset.change(transform_run, updated_params)
    end)
    |> Repo.transaction()
  end

  @doc """
  Completes a TransformRun.

  Creates a new derived dataset with the given `objects_or_params` and
  updates the given TransformRun's `status`, `completed_at`, and `output` fields.

  If there are more transforms left in the pipeline, updates the
  next TransformRun's `input` with the created dataset. Otherwise,
  marks the PipelineRun as `:completed`.

  Fails if the given TransformRun is not `:running` or if the PipelineRun
  is not `:running`.

  ## Examples

      iex> complete_transform_run(some_transform_run, some_object_params)
      {:ok, _changes}

      iex> complete_transform_run(some_invalid_transform_run, some_object_params)
      {:error, _failed_operation, _value, _changes}

  """
  @spec complete_transform_run(%TransformRun{}, [map] | [%Object{}]) :: {:ok, map} | {:error, atom, term, map}
  def complete_transform_run(%TransformRun{} = transform_run, objects_or_params) do
    Multi.new()
    |> Multi.run(:validate_transform_running, fn _repo, _changes ->
      # Check within transaction to prevent race conditions
      case get_transform_run!(transform_run.id).status do
        :running -> {:ok, :running}
        status -> {:error, status}
      end
    end)
    |> Multi.run(:pipeline_run, fn _repo, _changes ->
      %PipelineRun{} = pipeline_run = get_pipeline_run!(transform_run.pipeline_run_id)
      {:ok, pipeline_run}
    end)
    |> Multi.run(:validate_pipeline_running, fn _repo, %{pipeline_run: %PipelineRun{} = pipeline_run} ->
      case pipeline_run.status do
        :running -> {:ok, :running}
        status -> {:error, status}
      end
    end)
    |> Multi.run(:dataset, fn _repo, %{pipeline_run: %PipelineRun{pipeline: %Pipeline{} = pipeline}} ->
      dataset_params = %{
        name: "Derived from #{pipeline.name} T#{transform_run.order_index + 1}",
        type: :derived,
      }

      {:ok, %{dataset: %Dataset{} = dataset}} = Warehouse.create_dataset(dataset_params, objects_or_params)
      {:ok, dataset}
    end)
    |> Multi.run(:update_transform_run, fn _changes, %{dataset: %Dataset{} = dataset} ->
      updated_params = %{
        status: :complete,
        completed_at: DateTime.utc_now(),
        output_id: dataset.id,
      }
      Repo.update Ecto.Changeset.change(transform_run, updated_params)
    end)
    |> Multi.run(:maybe_update_next_transform_run, fn _changes, %{pipeline_run: %PipelineRun{} = pipeline_run, dataset: %Dataset{} = dataset} ->
      case Enum.at(pipeline_run.transform_runs, transform_run.order_index + 1) do
        %TransformRun{} = next_run ->
          case next_run.input_id do
            nil -> Repo.update Ecto.Changeset.change(next_run, %{input_id: dataset.id})
            _ -> {:error, :next_transform_already_has_input}
          end

        nil ->
          {:ok, :no_more_transform_runs}
      end
    end)
    |> Multi.run(:maybe_complete_pipeline_run, fn _changes, %{pipeline_run: %PipelineRun{} = pipeline_run} ->
      case Enum.at(pipeline_run.transform_runs, transform_run.order_index + 1) do
        nil ->
          updated_params = %{
            status: :complete,
            completed_at: DateTime.utc_now(),
          }
          Repo.update Ecto.Changeset.change(pipeline_run, updated_params)

        _next_run ->
          {:ok, :still_has_more_transform_runs}
      end
    end)
    |> Repo.transaction()
  end
end
