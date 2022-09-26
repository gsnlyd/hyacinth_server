defmodule HyacinthWeb.DatasetLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, Labeling}
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.LabelJob

  def mount(params, _session, socket) do
    dataset = Warehouse.get_dataset!(params["dataset_id"])
    socket = assign(socket, %{
      dataset: dataset,
      jobs: Labeling.list_label_jobs(dataset),
      objects: Warehouse.list_objects(dataset),

      tab: :objects,
    })
    {:ok, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "jobs" -> :jobs
      "objects" -> :objects
    end
    {:noreply, assign(socket, :tab, tab)}
  end
end
