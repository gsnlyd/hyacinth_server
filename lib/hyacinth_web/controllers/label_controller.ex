defmodule HyacinthWeb.LabelController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Warehouse, Labeling}

  def index(conn, %{"job_id" => job_id, "element_index" => element_index}) do
    element_index = String.to_integer(element_index)
    job = Labeling.get_label_job!(job_id)
    elements = Warehouse.list_dataset_elements(job.dataset_id)
    element = Enum.at(elements, element_index)

    IO.inspect job
    IO.inspect element_index

    render(conn, "index.html", job: job, element: element, element_index: element_index)
  end
end
