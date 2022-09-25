defmodule HyacinthWeb.DatasetLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Warehouse

  def mount(params, _session, socket) do
    socket = assign(socket, %{
      dataset: Warehouse.get_dataset!(params["dataset_id"])
    })
    {:ok, socket}
  end
end
