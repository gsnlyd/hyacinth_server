defmodule HyacinthWeb.LabelController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Warehouse, Labeling}

  def index(conn, %{"job_id" => job_id, "element_index" => element_index}) do
    element_index = String.to_integer(element_index)
    job = Labeling.get_label_job!(job_id)
    elements = Warehouse.list_dataset_elements(job.dataset_id)
    element = Enum.at(elements, element_index)

    labels = Labeling.list_label_entries(job, element)

    IO.inspect job
    IO.inspect element_index

    render(conn, "index.html", job: job, element: element, labels: labels, element_index: element_index)
  end

  def set_label(conn, %{"job_id" => job_id, "element_id" => element_id, "label_value" => label_value}) do
    job = Labeling.get_label_job!(job_id)
    element = Warehouse.get_element!(element_id)
    Labeling.create_label_entry(job, element, label_value)

    redirect(conn, to: Routes.label_path(conn, :index, job.id, 0))
  end
end
