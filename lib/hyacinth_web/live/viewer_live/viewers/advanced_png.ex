defmodule HyacinthWeb.ViewerLive.Viewers.AdvancedPNG do
  use HyacinthWeb, :live_view

  alias Hyacinth.Warehouse

  def mount(_params, session, socket) do
    socket = assign(socket, %{
      object: Warehouse.get_object!(session["object_id"]),
      unique_id: session["unique_id"] || 0,
    })
    {:ok, socket}
  end
end
