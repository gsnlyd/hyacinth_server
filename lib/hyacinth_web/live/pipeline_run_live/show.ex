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

  def dataset_link_card(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="text-sm text-gray-400"><%= @label %> Dataset</div>
      <%= live_redirect to: Routes.live_path(@socket, HyacinthWeb.DatasetLive.Show, @dataset),
          class: "flex-1 mt-1 p-2 w-48 text-sm bg-black bg-opacity-30 border border-gray-600 hover:border-gray-500 rounded" do %>
        <div class="text-gray-300"><%= @dataset.name %></div>
        <div class="text-gray-500">
          <%= case @dataset.type do %>
          <% :root -> %>
            <div>Root Dataset</div>
          <% :derived -> %>
            <div>Derived Dataset</div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_info({:pipeline_run_updated, {_id, _status}}, socket) do
    pipeline_run = Assembly.get_pipeline_run!(socket.assigns.pipeline_run.id)
    {:noreply, assign(socket, :pipeline_run, pipeline_run)}
  end
end
