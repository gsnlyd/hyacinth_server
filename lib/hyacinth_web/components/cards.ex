defmodule HyacinthWeb.Components.Cards do
  use Phoenix.Component
  alias HyacinthWeb.Router.Helpers, as: Routes

  import HyacinthWeb.Components.BasicComponents

  alias Hyacinth.Warehouse.DatasetStats

  def dataset_card(%{dataset_stats: %DatasetStats{}} = assigns) do
    ~H"""
    <.link_card to={Routes.live_path(@socket, HyacinthWeb.DatasetLive.Show, @dataset_stats.dataset)}>
      <:header><%= @dataset_stats.dataset.name %></:header>

      <:tag>
        <%= case @dataset_stats.dataset.type do %>
        <% :root -> %>
          <div class="pill pill-violet">Root Dataset</div>
        <% :derived -> %>
          <div class="pill pill-orange">Derived Dataset</div>
        <% end %>
      </:tag>

      <:body>
        <div class="mt-1 text-sm text-gray-500">
          <span><%= @dataset_stats.num_objects %> images</span>
          &bull;
          <span><%= @dataset_stats.num_jobs %> labeling jobs</span>
        </div>
      </:body>

      <:footer>Created <%= Calendar.strftime(@dataset_stats.dataset.inserted_at, "%c") %></:footer>
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
          <%= case length(@pipeline.runs) do %>
          <% 0 -> %>
            <div class="pill pill-gray">0 runs</div>
          <% 1 -> %>
            <div class="pill pill-green">1 run</div>
          <% num_runs -> %>
            <div class="pill pill-green"><%= num_runs %> runs</div>
          <% end %>
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

      <:body>
        <div class="mt-1 text-xs text-gray-500">
          <%= @job.description || "No description." %>
        </div>
      </:body>

      <:footer>Created <%= Calendar.strftime(@job.inserted_at, "%c") %></:footer>
    </.link_card>
    """
  end

  def label_session_progress_card(assigns) do
    assigns = assign_new(assigns, :use_job_for_header, fn -> false end)
    ~H"""
    <.link_card to={Routes.live_path(@socket, HyacinthWeb.LabelSessionLive.Show, @progress.session)}>
      <:header>
        <%= if @use_job_for_header do %>
          <div><%= @progress.session.job.name %></div>
          <div class="text-xs text-gray-500 font-normal"><%= @progress.session.user.email %></div>
        <% else %>
          <%= @progress.session.user.email %>
        <% end %>
      </:header>

      <:tag>
        <%= cond do %>
        <% @progress.num_labeled == 0 -> %>
          <div class="pill pill-gray">Not Started</div>
        <% @progress.num_labeled < @progress.num_total -> %>
          <div class="pill pill-yellow">In Progress</div>
        <% true -> %>
          <div class="pill pill-green">Complete</div>
        <% end %>
      </:tag>

      <:body>
        <div class="mt-1 flex items-center space-x-2">
          <div class="flex-1 h-1.5 bg-gray-600 rounded-full">
            <div
              class={["h-full rounded-full bg-opacity-70", if(@progress.num_labeled < @progress.num_total, do: "bg-yellow-400", else: "bg-green-400")]}
              style={"width: #{if(@progress.num_labeled == 0, do: 0, else: (@progress.num_labeled / (@progress.num_total) * 100))}%"}
            />
          </div>

          <div class="text-sm text-gray-400 font-medium">
            <span><%= @progress.num_labeled %></span>
            <span>/</span>
            <span><%= @progress.num_total %></span>
          </div>
        </div>
      </:body>

      <:footer>Created <%= Calendar.strftime(@progress.session.inserted_at, "%c") %></:footer>
    </.link_card>
    """
  end
end
