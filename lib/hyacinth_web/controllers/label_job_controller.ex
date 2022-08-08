defmodule HyacinthWeb.LabelJobController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Warehouse, Labeling}
  alias Hyacinth.Labeling.LabelJob

  def index(conn, _params) do
    label_jobs = Labeling.list_label_jobs()
    render(conn, "index.html", label_jobs: label_jobs)
  end

  def new(conn, _params) do
    changeset = Labeling.change_label_job(%LabelJob{})
    datasets = Warehouse.list_datasets()
    render(conn, "new.html", changeset: changeset, datasets: datasets)
  end

  def create(conn, %{"label_job" => label_job_params}) do
    case Labeling.create_label_job(label_job_params) do
      {:ok, label_job} ->
        conn
        |> put_flash(:info, "Label job created successfully.")
        |> redirect(to: Routes.label_job_path(conn, :show, label_job))

      {:error, %Ecto.Changeset{} = changeset} ->
        datasets = Warehouse.list_datasets()
        render(conn, "new.html", changeset: changeset, datasets: datasets)
    end
  end

  def show(conn, %{"id" => id}) do
    label_job = Labeling.get_label_job!(id)
    render(conn, "show.html", label_job: label_job)
  end

  def edit(conn, %{"id" => id}) do
    label_job = Labeling.get_label_job!(id)
    changeset = Labeling.change_label_job(label_job)
    render(conn, "edit.html", label_job: label_job, changeset: changeset)
  end

  def update(conn, %{"id" => id, "label_job" => label_job_params}) do
    label_job = Labeling.get_label_job!(id)

    case Labeling.update_label_job(label_job, label_job_params) do
      {:ok, label_job} ->
        conn
        |> put_flash(:info, "Label job updated successfully.")
        |> redirect(to: Routes.label_job_path(conn, :show, label_job))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", label_job: label_job, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    label_job = Labeling.get_label_job!(id)
    {:ok, _label_job} = Labeling.delete_label_job(label_job)

    conn
    |> put_flash(:info, "Label job deleted successfully.")
    |> redirect(to: Routes.label_job_path(conn, :index))
  end
end
