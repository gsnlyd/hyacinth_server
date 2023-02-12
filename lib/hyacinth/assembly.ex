defmodule Hyacinth.Assembly do
  @moduledoc """
  The Assembly context defines functions for creating
  pipelines which transform datasets.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Phoenix.PubSub

  alias Hyacinth.Repo

  alias Hyacinth.Warehouse

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.{Dataset, Object, FormatType}
  alias Hyacinth.Assembly.{Pipeline, Transform, PipelineRun, TransformRun, Driver}

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
      preload: [:creator, :transforms, :runs]
    )
  end

  @doc """
  Returns a list of all Pipelines created by the given user
  with their relations preloaded.

  See `list_pipelines_preloaded/0` for details.

  ## Examples

      iex> list_running_pipeline_runs_preloaded(some_user)
      [%Pipeline{}, %Pipeline{}, ...]

  """
  def list_pipelines_preloaded(%User{} = user) do
    Repo.all(
      from p in Pipeline,
      where: p.creator_id == ^user.id,
      preload: [:creator, :transforms, :runs]
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
  Gets a single Pipeline with preloads.

  The following fields are preloaded:
    * `creator`
    * `transforms`
    * `runs`
    * `PipelineRun.ran_by`
    * `PipelineRun.transform_runs`
    * `TransformRun.input`
    * `TransformRun.output`

  ## Examples

      iex> get_pipeline_preloaded!(123)
      %Pipeline{...}

      iex> get_pipeline_preloaded!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_pipeline_preloaded!(term) :: %Pipeline{}
  def get_pipeline_preloaded!(id) do
    Repo.one!(
      from p in Pipeline,
      where: p.id == ^id,
      select: p,
      preload: [:creator, :transforms, runs: [:ran_by, transform_runs: [:input, :output]]]
    )
  end

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
  Returns the input format of the first non-pure
  transform in the given list of transforms.

  If all transforms are pure, returns `:any`.

  ## Examples

      iex> get_input_format(some_transforms)
      :dicom

      iex> get_input_format(some_other_transforms)
      :any

  """
  @spec get_input_format([%Transform{}]) :: FormatType.t | :any
  def get_input_format(transforms) when is_list(transforms) do
    Enum.find_value(transforms, :any, fn %Transform{} = transform ->
      if Driver.pure?(transform.driver) do
        false
      else
        Driver.input_format(transform.driver, transform.options)
      end
    end)
  end

  @doc """
  Checks whether each transform's input format matches the
  previous output format.

  Returns a list the same length as the input `transforms`,
  where each element is either an error tuple `{expected, found}`
  or nil if the formats match.

  If `starting_format` is not provided (as it is not known
  at pipeline creation, only once the pipeline is run),
  errors are checked starting at the first output
  format found (i.e. the first non-pure transform).

  When pure transforms are present, the previous format
  will cascade as would be expected.

  ## Examples

      iex> check_transform_formats(some_transforms, :dicom)
      [
        {:dicom, :png},
        nil,
        nil
      ]

      iex> check_transform_formats(some_other_transforms)
      [
        nil,
        {:nifti, :png},
        nil
      ]

  """
  @spec check_transform_formats([%Transform{}], atom | nil) :: [{atom, atom} | nil]
  def check_transform_formats(transforms, starting_format \\ nil) when is_list(transforms) do
    transforms
    |> Enum.map_reduce(starting_format, fn %Transform{} = transform, prev_output ->
      if Driver.pure?(transform.driver) do
        {nil, prev_output}
      else
        cur_input = Driver.input_format(transform.driver, transform.options)
        cur_output = Driver.output_format(transform.driver, transform.options)

        error =
          if prev_output != nil and prev_output != cur_input do
            {cur_input, prev_output}
          end

        {error, cur_output}
      end
    end)
    |> elem(0)
  end

  @doc """
  Lists all pipeline runs which are currently
  running with preloads.

  The following fields are preloaded:
    * `ran_by`
    * `pipeline`
    * `transform_runs`
    * `TransformRun.input`
    * `TransformRun.output`

  ## Examples

      iex> list_running_pipeline_runs_preloaded()
      [%PipelineRun{}, %PipelineRun{}, ...]

  """
  def list_running_pipeline_runs_preloaded do
    Repo.all(
      from pr in PipelineRun,
      where: pr.status == :running,
      select: pr,
      preload: [:ran_by, :pipeline, transform_runs: [:input, :output]]
    )
  end

  @doc """
  Gets a single PipelineRun.

  The following attributes are preloaded:
    * `ran_by`
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
      preload: [:ran_by, :pipeline, transform_runs: [:transform, :input, :output]]
    )
  end

  @doc """
  Gets the status of a `Hyacinth.Assembly.PipelineRun`.

  ## Examples

      iex> get_pipeline_run_status!(123)
      :running

      iex> get_pipeline_run_status!(124)
      :complete

      iex> get_pipeline_run_status!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_pipeline_run_status!(term) :: atom
  def get_pipeline_run_status!(id) do
    Repo.one!(
      from pr in PipelineRun,
      where: pr.id == ^id,
      select: pr.status
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
  Subscribes to updates for a Pipeline or PipelineRun.

  If a `Hyacinth.Assembly.Pipeline` is passed, updates
  are sent for all runs associated with that Pipeline.

  If a `Hyacinth.Assembly.PipelineRun` is passed, updates
  are sent for only that run.

  Update messages have the following format:
  `{:pipeline_run_updated, pipeline_run_id}`

  ## Examples

      iex> my_pipeline = %Pipeline{...}
      iex> subscribe_pipeline_run_updates(my_pipeline)
      :ok

      iex> my_run = %PipelineRun{...}
      iex> subscribe_pipeline_run_updates(my_run)
      :ok

      # In your LiveView:
      def handle_info({:pipeline_run_updated, run_id}, socket) do
        # Handle event
        {:noreply, socket}
      end

  """
  @spec subscribe_pipeline_run_updates(%Pipeline{}) :: :ok
  def subscribe_pipeline_run_updates(%Pipeline{id: pipeline_id}) do
    :ok = PubSub.subscribe(Hyacinth.PubSub, "pipeline_run_updates:pipeline_id:#{pipeline_id}")
  end

  @spec subscribe_pipeline_run_updates(%PipelineRun{}) :: :ok
  def subscribe_pipeline_run_updates(%PipelineRun{id: pipeline_run_id}) do
    :ok = PubSub.subscribe(Hyacinth.PubSub, "pipeline_run_updates:pipeline_run_id:#{pipeline_run_id}")
  end

  @doc """
  Subscribes to all PipelineRun updates.

  See `subscribe_pipeline_run_updates/1` for
  details on the message format.

  ## Examples

      iex> subscribe_all_pipeline_run_updates()
      :ok

  """
  def subscribe_all_pipeline_run_updates do
    :ok = PubSub.subscribe(Hyacinth.PubSub, "pipeline_run_updates")
  end

  @doc false
  @spec broadcast_pipeline_run_update(%PipelineRun{}) :: :ok
  def broadcast_pipeline_run_update(%PipelineRun{id: pipeline_run_id, pipeline_id: pipeline_id}) do
    message = {:pipeline_run_updated, {pipeline_run_id, get_pipeline_run_status!(pipeline_run_id)}}
    PubSub.broadcast!(Hyacinth.PubSub, "pipeline_run_updates", message)
    PubSub.broadcast!(Hyacinth.PubSub, "pipeline_run_updates:pipeline_id:#{pipeline_id}", message)
    PubSub.broadcast!(Hyacinth.PubSub, "pipeline_run_updates:pipeline_run_id:#{pipeline_run_id}", message)
    :ok
  end

  @doc """
  Starts a TransformRun.

  Updates the `status` and `started_at` fields of
  the TransformRun.

  Fails if transform is not `:waiting`, pipeline is not `:running`,
  or previous transforms are not `:complete`.

  ## Examples

      iex> start_transform_run(some_transform_run)
      {:ok, _changes}

      iex> start_transform_run(invalid_transform_run)
      {:error, _failed_operation, _value, _changes}

  """
  @spec start_transform_run(%TransformRun{}) :: {:ok, map} | {:error, atom, term, map}
  def start_transform_run(%TransformRun{} = transform_run) do
    result =
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

    case result do
      {:ok, %{pipeline_run: pipeline_run}} -> :ok = broadcast_pipeline_run_update(pipeline_run)
      _ -> nil
    end

    result
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
    result =
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
          name: "Derived from Step #{transform_run.order_index + 1} of #{pipeline.name}",
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

    case result do
      {:ok, %{pipeline_run: pipeline_run}} -> :ok = broadcast_pipeline_run_update(pipeline_run)
      _ -> nil
    end

    result
  end
end
