defmodule HyacinthWeb.PipelineRunLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Assembly

  def mount(params, _session, socket) do
    pipeline_run = Assembly.get_pipeline_run!(params["pipeline_run_id"])
    socket = assign(socket, %{
      pipeline_run: pipeline_run,
    })
    {:ok, socket}
  end
end
