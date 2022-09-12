defmodule HyacinthWeb.UserLiveAuth do
  import Phoenix.LiveView
  alias HyacinthWeb.Router.Helpers, as: Routes

  alias Hyacinth.Accounts
  alias Hyacinth.Accounts.User

  def on_mount(:user, _params, %{"user_token" => user_token}, socket) do
    socket = assign_new(socket, :current_user, fn ->
      Accounts.get_user_by_session_token(user_token)
    end)

    case socket.assigns.current_user do
      %User{} ->
        {:cont, socket}
      nil ->
        {:halt, redirect(socket, to: Routes.user_session_path(socket, :new))}
    end
  end

  def on_mount(:user, _params, _session, socket) do
    {:halt, redirect(socket, to: Routes.user_session_path(socket, :new))}
  end
end
