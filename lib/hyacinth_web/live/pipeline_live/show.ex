defmodule HyacinthWeb.PipelineLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Assembly
  alias Hyacinth.Assembly.Runner

  def mount(params, _session, socket) do
    socket = assign(socket, %{
      pipeline: Assembly.get_pipeline!(params["pipeline_id"]),
    })

    {:ok, socket}
  end

  def handle_event("run_pipeline", _value, socket) do
    Runner.run_pipeline(socket.assigns.pipeline)
    {:noreply, socket}
  end
end
