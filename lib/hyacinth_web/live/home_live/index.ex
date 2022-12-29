defmodule HyacinthWeb.HomeLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, Assembly, Labeling}

  def mount(_params, _session, socket) do
    if connected?(socket), do: Assembly.subscribe_all_pipeline_run_updates()

    socket = assign(socket, %{
      user_sessions: Labeling.list_sessions_with_progress(socket.assigns.current_user),
      running_pipeline_runs: Assembly.list_running_pipeline_runs_preloaded(),

      datasets: Warehouse.list_datasets_with_stats(),
      pipelines: Assembly.list_pipelines_preloaded(),
      jobs: Labeling.list_label_jobs(),
    })
    {:ok, socket}
  end

  def handle_info({:pipeline_run_updated, {_id, _status}}, socket) do
    socket = assign(socket, %{
      running_pipeline_runs: Assembly.list_running_pipeline_runs_preloaded(),
    })
    {:noreply, socket}
  end
end
