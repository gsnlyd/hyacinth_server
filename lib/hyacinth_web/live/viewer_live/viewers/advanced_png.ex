defmodule HyacinthWeb.ViewerLive.Viewers.AdvancedPNG do
  use HyacinthWeb, :live_component

  alias Hyacinth.Warehouse

  def update(assigns, socket) do
    socket = assign(socket, %{
      object: Warehouse.get_object!(assigns.object_id),
      unique_id: assigns[:unique_id] || 0,
      collaboration: assigns[:collaboration] || false,
    })
    {:ok, socket}
  end
end
