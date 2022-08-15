defmodule HyacinthWeb.LabelController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Warehouse, Labeling}

  def index(conn, %{"job_id" => job_id, "object_index" => object_index}) do
    object_index = String.to_integer(object_index)
    job = Labeling.get_label_job!(job_id)
    objects = Warehouse.list_dataset_objects(job.dataset_id)
    object = Enum.at(objects, object_index)

    labels = []

    render(conn, "index.html", job: job, object: object, labels: labels, object_index: object_index)
  end
end
