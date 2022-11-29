defmodule HyacinthWeb.HomeLive.Index do
  use HyacinthWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
    })
    {:ok, socket}
  end
end
