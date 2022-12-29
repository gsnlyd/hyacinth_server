defmodule Hyacinth.Labeling do
  @moduledoc """
  The Labeling context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Hyacinth.Repo

  alias Hyacinth.Warehouse

  alias Hyacinth.Accounts.{User}
  alias Hyacinth.Warehouse.{Dataset, Object}
  alias Hyacinth.Labeling.{LabelJobType, LabelJob, LabelSession, LabelElement, LabelElementObject, LabelEntry, Note}

  @doc """
  Returns a list of all LabelJobs.

  ## Examples

      iex> list_label_jobs()
      [%LabelJob{}, ...]

  """
  @spec list_label_jobs() :: [%LabelJob{}]
  def list_label_jobs do
    Repo.all(LabelJob)
  end

  @doc """
  Returns a list of LabelJobs for the given dataset.

  ## Examples

      iex> list_label_jobs(some_dataset)
      [%LabelJob{}, ...]

  """
  @spec list_label_jobs(%Dataset{}) :: [%LabelJob{}]
  def list_label_jobs(%Dataset{} = dataset) do
    Repo.all(
      from lj in LabelJob,
      where: lj.dataset_id == ^dataset.id,
      select: lj
    )
  end

  @doc """
  Returns a list of all LabelJobs with preloads.

  The following fields are preloaded:
    * `dataset`

  """
  @spec list_label_jobs_preloaded() :: [%LabelJob{}]
  def list_label_jobs_preloaded() do
    Repo.all(
      from lj in LabelJob,
      select: lj,
      preload: [:dataset]
    )
  end

  @doc """
  Gets a single LabelJob.

  Raises `Ecto.NoResultsError` if the LabelJob does not exist.

  ## Examples

      iex> get_label_job!(123)
      %LabelJob{...}

      iex> get_label_job!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_label_job!(term) :: %LabelJob{}
  def get_label_job!(id), do: Repo.get!(LabelJob, id)

  @doc """
  Gets a single LabelJob with its blueprint session preloaded.

  ## Examples

      iex> get_label_job_with_blueprint(123)
      %LabelJob{...}

      iex> get_label_job_with_blueprint(456)
      ** (Ecto.NoResultsError)
      
  """
  @spec get_job_with_blueprint(term) :: %LabelJob{}
  def get_job_with_blueprint(id) do
    Repo.one!(
      from lj in LabelJob,
      where: lj.id == ^id,
      select: lj,
      preload: [dataset: [], blueprint: [elements: :objects]]
    )
  end

  @doc """
  Creates a new LabelJob.

  ## Examples

      iex> create_label_job(params, some_user)
      {:ok, %LabelJob{...}}

      iex>create_label_job(invalid_params, some_user)
      {:error, %Ecto.Changeset{...}}

  """
  @spec create_label_job(map, %User{}) :: {:ok, %LabelJob{}} | {:error, %Ecto.Changeset{}}
  def create_label_job(attrs \\ %{}, %User{} = created_by_user) do
    result =
      Multi.new()
      |> Multi.insert(:label_job, LabelJob.changeset(%LabelJob{created_by_user_id: created_by_user.id}, attrs))
      |> Multi.insert(:blueprint_session, fn %{label_job: %LabelJob{} = job} ->
        %LabelSession{blueprint: true, job_id: job.id}
      end)
      |> Multi.run(:elements, fn _repo, %{label_job: %LabelJob{} = job, blueprint_session: %LabelSession{} = blueprint} ->
        dataset = Warehouse.get_dataset!(job.dataset_id)
        objects_grouped = LabelJobType.group_objects(job.type, job.options, Warehouse.list_objects(dataset))

        elements =
          objects_grouped
          |> Enum.with_index()
          |> Enum.map(fn {objects, element_i} ->
            element = Repo.insert! %LabelElement{element_index: element_i, session_id: blueprint.id}

            objects
            |> Enum.with_index()
            |> Enum.map(fn {%Object{} = object, elobj_i} ->
              Repo.insert! %LabelElementObject{object_index: elobj_i, label_element_id: element.id, object_id: object.id}
            end)

            element
          end)

        {:ok, elements}
      end)
      |> Repo.transaction()

    # Match result for label_job insert and return job or error changeset
    # Errors for other steps in the multi are unexpected and thus raise
    case result do
      {:ok, %{label_job: %LabelJob{} = job}} ->
        {:ok, job}

      {:error, :label_job, %Ecto.Changeset{} = changeset, _changes} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a LabelJob.

  ## Examples

      iex> update_label_job(label_job, %{field: new_value})
      {:ok, %LabelJob{}}

      iex> update_label_job(label_job, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_label_job(%LabelJob{}, map) :: {:ok, %LabelJob{}} | {:error, %Ecto.Changeset{}}
  def update_label_job(%LabelJob{} = label_job, attrs) do
    label_job
    |> LabelJob.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking LabelJob changes.

  ## Examples

      iex> change_label_job(label_job)
      %Ecto.Changeset{data: %LabelJob{}}

  """
  @spec change_label_job(%LabelJob{}, map) :: %Ecto.Changeset{}
  def change_label_job(%LabelJob{} = label_job, attrs \\ %{}) do
    LabelJob.changeset(label_job, attrs)
  end



  @doc """
  Lists all (non-blueprint) sessions for the given LabelJob.

  ## Examples

      iex> list_sessions(some_job)
      [%LabelSession{}, %LabelSession{}, ...]

  """
  @spec list_sessions(%LabelJob{}) :: [%LabelSession{}]
  def list_sessions(%LabelJob{} = job) do
    Repo.all(
      from ls in LabelSession,
      where: (ls.job_id == ^job.id) and (not ls.blueprint),
      select: ls,
      preload: :user,
      order_by: ls.inserted_at
    )
  end

  defmodule LabelSessionProgress do
    @type t :: %__MODULE__{
      session: %LabelSession{},
      num_labeled: integer,
      num_total: integer,
    }
    @enforce_keys [:session, :num_labeled, :num_total]
    defstruct @enforce_keys
  end

  defp sessions_with_progress_query do
    num_labeled_query =
      from el in LabelElement,
      left_join: lab in assoc(el, :labels),
      group_by: el.session_id,
      select: %{session_id: el.session_id, num_labeled: count(lab.element_id, :distinct)}

    num_total_query =
      from el in LabelElement,
      group_by: el.session_id,
      select: %{session_id: el.session_id, num_total: count(el.id)}

    from ls in LabelSession,
    inner_join: nlquery in subquery(num_labeled_query),
    on: nlquery.session_id == ls.id,
    inner_join: ntquery in subquery(num_total_query),
    on: ntquery.session_id == ls.id,
    group_by: ls.id,
    select: %LabelSessionProgress{session: ls, num_labeled: nlquery.num_labeled, num_total: ntquery.num_total},
    preload: [:user, :job]
  end

  @doc """
  Lists all (non-blueprint) sessions for the given LabelJob or User,
  along with the number of elements within that session
  which have been labeled.

  The following fields are preloaded on the LabelSession:
    * `user`
    * `job`

  ## Examples

      iex> list_sessions_with_progress(job_or_user)
      [
        %LabelSessionProgress{session: %LabelSession{...}, num_labeled: 10, num_total: 30},
        %LabelSessionProgress{session: %LabelSession{...}, num_labeled: 3, num_total: 30},
        %LabelSessionProgress{session: %LabelSession{...}, num_labeled: 0, num_total: 30},
      ]

  """
  @spec list_sessions_with_progress(%LabelJob{} | %User{}) :: [%LabelSessionProgress{}]
  def list_sessions_with_progress(%LabelJob{} = job) do
    sessions_with_progress_query()
    |> where([ls], ls.job_id == ^job.id and (not ls.blueprint))
    |> Repo.all()
  end

  def list_sessions_with_progress(%User{} = user) do
    sessions_with_progress_query()
    |> where([ls], ls.user_id == ^user.id)
    |> Repo.all()
  end


  @doc """
  Gets a single LabelSession.

  ## Examples

      iex> get_label_session!(123)
      %LabelSession{...}

      iex> get_label_session!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_label_session!(term) :: %LabelSession{}
  def get_label_session!(id), do: Repo.get!(LabelSession, id)

  @doc """
  Gets a single LabelSession with its elements preloaded.

  ## Examples

      iex> get_label_session_with_elements!(123)
      %LabelSession{...}

      iex> get_label_session_with_elements!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_label_session_with_elements!(term) :: %LabelSession{}
  def get_label_session_with_elements!(id) do
    Repo.one!(
      from ls in LabelSession,
      where: ls.id == ^id,
      select: ls,
      preload: [job: [:dataset], user: [], elements: [:objects, :labels]]
    )
  end

  @doc """
  Creates a new LabelSession.

  ## Examples

      iex> create_label_session(some_job, some_user)
      %LabelSession{...}

  """
  @spec create_label_session(%LabelJob{}, %User{}) :: %LabelSession{}
  def create_label_session(%LabelJob{} = job, %User{} = user) do
    result =
      Multi.new()
      |> Multi.insert(:label_session, %LabelSession{blueprint: false, job_id: job.id, user_id: user.id})
      |> Multi.run(:elements, fn _repo, %{label_session: session} ->
        # Clone elements from job blueprint into new session
        blueprint = get_job_with_blueprint(job.id).blueprint
        elements =
          Enum.map(blueprint.elements, fn %LabelElement{} = bp_element ->
            element = Repo.insert! %LabelElement{element_index: bp_element.element_index, session_id: session.id}

            Enum.map(bp_element.label_element_objects, fn %LabelElementObject{} = bp_el_object ->
              Repo.insert! %LabelElementObject{object_index: bp_el_object.object_index, label_element_id: element.id, object_id: bp_el_object.object_id}
            end)

            element
          end)

        {:ok, elements}
      end)
      |> Repo.transaction()

    {:ok, %{label_session: %LabelSession{} = session}} = result
    session
  end

  @doc """
  Gets a single LabelElement by id.

  ## Examples

      iex> get_label_element!(123)
      %LabelElement{...}

      iex> get_label_element!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_label_element!(term) :: %LabelElement{}
  def get_label_element!(id), do: Repo.get!(LabelElement, id)

  @doc """
  Gets a single LabelElement.

  The following fields are preloaded:
    * `objects`
    * `note`

  ## Examples

      iex> get_label_element_preloaded!(123)
      %LabelElement{...}

      iex> get_label_element_preloaded!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_label_element_preloaded!(term) :: %LabelElement{}
  def get_label_element_preloaded!(id) do
    Repo.one!(
      from le in LabelElement,
      where: le.id == ^id,
      select: le,
      preload: [:objects, :note]
    )
  end

  @doc """
  Gets a single LabelElement with the given element_index from a LabelSesssion.

  ## Examples

      iex> get_label_element!(some_session, 3)
      %LabelElement{element_index: 3, ...}

  """
  @spec get_label_element!(%LabelSession{}, integer) :: %LabelElement{}
  def get_label_element!(%LabelSession{} = session, element_index) do
    Repo.one!(
      from le in LabelElement,
      where: le.session_id == ^session.id and le.element_index == ^element_index,
      select: le,
      preload: [:objects, :note]
    )
  end

  @doc """
  Creates a new LabelEntry.

  Raises if user does not match session user or label_value
  is not a valid option for the job.

  ## Examples

      iex> create_label_entry!(some_element, some_user, "some label")
      %LabelEntry{...}

  """
  @spec create_label_entry!(%LabelElement{}, %User{}, String.t) :: %LabelEntry{}
  def create_label_entry!(%LabelElement{} = element, %User{} = user, label_value) when is_binary(label_value) do
    result =
      Multi.new()
      |> Multi.run(:label_session, fn _repo, _values ->
        label_session = get_label_session!(element.session_id)
        {:ok, label_session}
      end)
      |> Multi.run(:label_job, fn _repo, %{label_session: %LabelSession{} = label_session} ->
        label_job = get_label_job!(label_session.job_id)
        {:ok, label_job}
      end)
      |> Multi.run(:validate_user, fn _repo, %{label_session: %LabelSession{} = label_session} ->
        if user.id == label_session.user_id do
          {:ok, true}
        else
          {:error, :wrong_session_user}
        end
      end)
      |> Multi.run(:validate_label_value, fn _repo, %{label_job: %LabelJob{} = label_job} ->
        object_label_options = LabelJobType.list_object_label_options(label_job.type, label_job.options)
        if label_value in label_job.label_options or (object_label_options != nil && label_value in object_label_options) do
          {:ok, true}
        else
          {:error, :invalid_label_value}
        end
      end)
      |> Multi.insert(:label_entry, %LabelEntry{
        value: %LabelEntry.Value{
          option: label_value
        },
        metadata: %LabelEntry.Metadata{
          started_at: DateTime.utc_now(),  # TODO: accept actual times
          completed_at: DateTime.utc_now()
        },
        element_id: element.id,
      })
      |> Repo.transaction()

    {:ok, %{label_entry: %LabelEntry{} = label_entry}} = result
    label_entry
  end

  @doc """
  Lists all labels for the given element. Labels are returned
  in descending order by creation timestamp.

  ## Examples

      iex> list_element_labels(some_element)
      [%LabelEntry{}, ...]

  """
  @spec list_element_labels(%LabelElement{}) :: [%LabelEntry{}]
  def list_element_labels(%LabelElement{} = element) do
    Repo.all(
      from entry in LabelEntry,
      where: entry.element_id == ^element.id,
      select: entry,
      order_by: [desc: entry.inserted_at]
    )
  end

  @doc """
  Creates a note for the given element.
  """
  @spec create_note(%User{}, %LabelElement{}, map) :: {:ok, map} | {:error, atom, term, map}
  def create_note(%User{} = user, %LabelElement{} = element, params) do
    Multi.new()
    |> Multi.run(:validate_user, fn _repo, _values ->
      %User{} = session_user =
        Repo.one(
          from sess in LabelSession,
          where: sess.id == ^element.session_id,
          inner_join: u in assoc(sess, :user),
          select: u
        )

      if user.id == session_user.id do
        {:ok, true}
      else
        {:error, :wrong_label_session_user}
      end
    end)
    |> Multi.insert(:note, Note.changeset(%Note{element_id: element.id}, params))
    |> Repo.transaction()
  end

  @doc """
  Updates a note.
  """
  @spec update_note(%User{}, %Note{}, map) :: {:ok, map} | {:error, atom, term, map}
  def update_note(%User{} = user, %Note{} = note, params) do
    Multi.new()
    |> Multi.run(:validate_user, fn _repo, _values ->
      %User{} = session_user =
        Repo.one(
          from el in LabelElement,
          where: el.id == ^note.element_id,
          inner_join: sess in assoc(el, :session),
          inner_join: u in assoc(sess, :user),
          select: u
        )

      if user.id == session_user.id do
        {:ok, true}
      else
        {:error, :wrong_label_session_user}
      end
    end)
    |> Multi.update(:note, Note.changeset(note, params))
    |> Repo.transaction()
  end
end
