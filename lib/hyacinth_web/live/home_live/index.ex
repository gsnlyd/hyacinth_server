defmodule HyacinthWeb.HomeLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, Assembly, Labeling}

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      datasets: Warehouse.list_datasets_with_counts(),
      pipelines: Assembly.list_pipelines_preloaded(),
      jobs: Labeling.list_label_jobs(),
    })
    {:ok, socket}
  end
end
