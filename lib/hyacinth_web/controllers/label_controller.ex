defmodule HyacinthWeb.LabelController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Warehouse, Labeling}

  def index(conn, %{"job_id" => job_id, "object_index" => object_index}) do
    object_index = String.to_integer(object_index)
    job = Labeling.get_label_job!(job_id)
    objects = Warehouse.list_dataset_objects(job.dataset_id)
    object = Enum.at(objects, object_index)

    labels = Labeling.list_label_entries(job, object)

    render(conn, "index.html", job: job, object: object, labels: labels, object_index: object_index)
  end

  def set_label(conn, %{"job_id" => job_id, "object_id" => object_id, "label_value" => label_value}) do
    job = Labeling.get_label_job!(job_id)
    object = Warehouse.get_object!(object_id)
    Labeling.create_label_entry(job, object, conn.assigns.current_user, label_value)

    redirect(conn, to: Routes.label_path(conn, :index, job.id, 0))
  end
end
