defmodule Hyacinth.Labeling do
  @moduledoc """
  The Labeling context.
  """

  import Ecto.Query, warn: false
  alias Hyacinth.Repo

  alias Hyacinth.Labeling.LabelJob

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
  Creates a label_job.

  ## Examples

      iex> create_label_job(%{field: value})
      {:ok, %LabelJob{}}

      iex> create_label_job(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_label_job(attrs \\ %{}) do
    # TODO: accept dataset_id as parameter
    %LabelJob{dataset_id: 1}
    |> LabelJob.changeset(attrs)
    |> Repo.insert()
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
  Deletes a label_job.

  ## Examples

      iex> delete_label_job(label_job)
      {:ok, %LabelJob{}}

      iex> delete_label_job(label_job)
      {:error, %Ecto.Changeset{}}

  """
  def delete_label_job(%LabelJob{} = label_job) do
    Repo.delete(label_job)
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
