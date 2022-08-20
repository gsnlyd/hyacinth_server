defmodule Hyacinth.Labeling do
  @moduledoc """
  The Labeling context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Hyacinth.Repo

  alias Hyacinth.Warehouse

  alias Hyacinth.Accounts.{User}
  alias Hyacinth.Labeling.{LabelJob, LabelSession, LabelElement, LabelElementObject}

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
        objects = Warehouse.list_dataset_objects(job.dataset_id)
        elements = Enum.map(Enum.with_index(objects), fn {o, i} ->
          element = Repo.insert! %LabelElement{element_index: i, session_id: blueprint.id}
          Repo.insert! %LabelElementObject{object_index: 0, label_element_id: element.id, object_id: o.id}

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
end
