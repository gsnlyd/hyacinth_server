defmodule HyacinthWeb.ViewerLive.Viewers.WebImage do
  use HyacinthWeb, :live_view

  alias Hyacinth.Warehouse

  def mount(_params, session, socket) do
    socket = assign(socket, %{
      object: Warehouse.get_object!(session["object_id"]),
    })
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <img
      class="w-full aspect-square object-contain bg-black rounded"
      src={Routes.image_path(@socket, :show, @object.id)}
      style="height: calc(100vh - 16rem);"
    />
    """
  end
end
