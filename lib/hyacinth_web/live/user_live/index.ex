defmodule HyacinthWeb.UserLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.Accounts

  alias Hyacinth.Accounts.User

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      users: Accounts.list_users(),
    })
    {:ok, socket}
  end
end
