defmodule Hyacinth.Labeling do
  @moduledoc """
  The Labeling context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Hyacinth.Repo

  alias Hyacinth.Warehouse

  alias Hyacinth.Accounts.{User}
  alias Hyacinth.Warehouse.{Object}
  alias Hyacinth.Labeling.{LabelType, LabelJob, LabelSession, LabelElement, LabelElementObject, LabelEntry}

  @doc """
  Returns the list of label_jobs.

  ## Examples

      iex> list_label_jobs()
      [%LabelJob{}, ...]

  """
  def list_label_jobs do
    Repo.all(LabelJob)
  end

  @doc """
  Gets a single label_job.

  Raises `Ecto.NoResultsError` if the Label job does not exist.

  ## Examples

      iex> get_label_job!(123)
      %LabelJob{}

      iex> get_label_job!(456)
      ** (Ecto.NoResultsError)

  """
  def get_label_job!(id), do: Repo.get!(LabelJob, id)

  @doc """
  Gets a single LabelJob with its blueprint session preloaded.
  """
  def get_job_with_blueprint(id) do
    Repo.one!(
      from lj in LabelJob,
      where: lj.id == ^id,
      select: lj,
      preload: [dataset: [], blueprint: [elements: :objects]]
    )
  end

  @doc """
  Creates a label_job.
  """
  def create_label_job(attrs \\ %{}, %User{} = created_by_user) do
    result =
      Multi.new()
      |> Multi.insert(:label_job, LabelJob.changeset(%LabelJob{created_by_user_id: created_by_user.id}, attrs))
      |> Multi.insert(:blueprint_session, fn %{label_job: %LabelJob{} = job} ->
        %LabelSession{blueprint: true, job_id: job.id}
      end)
      |> Multi.run(:elements, fn _repo, %{label_job: %LabelJob{} = job, blueprint_session: %LabelSession{} = blueprint} ->
        objects_grouped = LabelType.group_objects(job, Warehouse.list_dataset_objects(job.dataset_id))

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
  Updates a label_job.

  ## Examples

      iex> update_label_job(label_job, %{field: new_value})
      {:ok, %LabelJob{}}

      iex> update_label_job(label_job, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_label_job(%LabelJob{} = label_job, attrs) do
    label_job
    |> LabelJob.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking label_job changes.

  ## Examples

      iex> change_label_job(label_job)
      %Ecto.Changeset{data: %LabelJob{}}

  """
  def change_label_job(%LabelJob{} = label_job, attrs \\ %{}) do
    LabelJob.changeset(label_job, attrs)
  end



  @doc """
  Gets a single LabelSession.
  """
  def get_label_session!(id), do: Repo.get!(LabelSession, id)

  def get_label_session_with_elements!(id) do
    Repo.one!(
      from ls in LabelSession,
      where: ls.id == ^id,
      select: ls,
      preload: [job: [:dataset], user: [], elements: :objects]
    )
  end

  @doc """
  """
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
  """
  def get_label_element!(id), do: Repo.get!(LabelElement, id)

  @doc """
  Gets a single LabelElement with the given element_index from a LabelSesssion.
  """
  def get_label_element!(%LabelSession{} = session, element_index) do
    Repo.one!(
      from le in LabelElement,
      where: le.session_id == ^session.id and le.element_index == ^element_index,
      select: le,
      preload: :objects
    )
  end

  @doc """
  """
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
        if label_value in label_job.label_options do
          {:ok, true}
        else
          {:error, :invalid_label_value}
        end
      end)
      |> Multi.insert(:label_entry, %LabelEntry{label_value: label_value, element_id: element.id})
      |> Repo.transaction()

    {:ok, %{label_entry: %LabelEntry{} = label_entry}} = result
    label_entry
  end

  @doc """
  """
  def list_element_labels(%LabelElement{} = element) do
    Repo.all(
      from entry in LabelEntry,
      where: entry.element_id == ^element.id,
      select: entry,
      order_by: [desc: entry.inserted_at]
    )
  end
end
