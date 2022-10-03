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

  def tab_button(assigns) do
    button_class =
      "px-2 pb-1 border-purple-400 transition" <>
        if Atom.to_string(assigns.cur_tab) == assigns.tab do
          "text-white border-b-2"
        else
          "px-1 text-gray-400 hover:text-white"
        end
    assigns = assign(assigns, :button_class, button_class)

    ~H"""
    <button class={@button_class} phx-click={@event} phx-value-tab={@tab}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "jobs" -> :jobs
      "objects" -> :objects
    end
    {:noreply, assign(socket, :tab, tab)}
  end
end
