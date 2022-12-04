defmodule HyacinthWeb.Components.Cards do
  use Phoenix.Component
  alias HyacinthWeb.Router.Helpers, as: Routes

  import HyacinthWeb.Components.BasicComponents

  def dataset_card(assigns) do
    ~H"""
    <.link_card to={Routes.live_path(@socket, HyacinthWeb.DatasetLive.Show, @dataset)}>
      <:header><%= @dataset.name %></:header>

      <:tag>
        <%= case @dataset.type do %>
        <% :root -> %>
          <div class="pill pill-violet">Root Dataset</div>
        <% :derived -> %>
          <div class="pill pill-orange">Derived Dataset</div>
        <% end %>
      </:tag>

      <:body>
        <%= if @object_count && @job_count do %>
          <div class="text-gray-400">
            <span><%= @object_count %> objects</span>
            &bull;
            <span><%= @job_count %> jobs</span>
          </div>
        <% end %>
      </:body>

      <:footer>Created <%= Calendar.strftime(@dataset.inserted_at, "%c") %></:footer>
    </.link_card>
    """
  end

  def pipeline_card(assigns) do
    ~H"""
    <.link_card to={Routes.live_path(@socket, HyacinthWeb.PipelineLive.Show, @pipeline)}>
      <:header><%= @pipeline.name %></:header>

      <:tag>
        <%= if Enum.any?(@pipeline.runs, &(&1.status == :running)) do %>
          <div class="pill pill-yellow">Running</div>
        <% else %>
          <div class="pill pill-green"><%= length(@pipeline.runs) %> runs</div>
        <% end %>
      </:tag>

      <:body>
        <div class="mt-1 text-xs text-gray-400">
          <%= for {transform, i} <- Enum.with_index(@pipeline.transforms) do %>
            <span>
              <%= if i > 0 do %>
                <span>&rarr;</span>
              <% end %>
              <span><%= transform.driver %></span>
            </span>
          <% end %>
        </div>
      </:body>

      <:footer>Created <%= Calendar.strftime(@pipeline.inserted_at, "%c") %></:footer>
    </.link_card>
    """
  end

  def label_job_card(assigns) do
    ~H"""
    <.link_card to={Routes.live_path(@socket, HyacinthWeb.LabelJobLive.Show, @job)}>
      <:header><%= @job.name %></:header>
      <:tag>
        <%= case @job.type do %>
        <% :classification -> %>
          <div class="pill pill-green">Classification</div>
        <% :comparison_exhaustive -> %>
          <div class="pill pill-blue">Comparison</div>
        <% end %>
      </:tag>

      <:footer>Created <%= Calendar.strftime(@job.inserted_at, "%c") %></:footer>
    </.link_card>
    """
  end
end
