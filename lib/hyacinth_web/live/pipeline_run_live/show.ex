defmodule HyacinthWeb.PipelineRunLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Assembly
  alias Hyacinth.Assembly.{TransformRun}

  def mount(params, _session, socket) do
    pipeline_run = Assembly.get_pipeline_run!(params["pipeline_run_id"])

    if connected?(socket), do: Assembly.subscribe_pipeline_run_updates(pipeline_run)

    socket = assign(socket, %{
      pipeline_run: pipeline_run,
    })
    {:ok, socket}
  end

  def handle_info({:pipeline_run_updated, {_id, _status}}, socket) do
    pipeline_run = Assembly.get_pipeline_run!(socket.assigns.pipeline_run.id)
    {:noreply, assign(socket, :pipeline_run, pipeline_run)}
  end
end
