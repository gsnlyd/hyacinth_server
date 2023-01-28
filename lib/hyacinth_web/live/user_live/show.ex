defmodule HyacinthWeb.UserLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Accounts, Assembly, Labeling}

  alias Hyacinth.Accounts.User

  def mount(params, _session, socket) do
    %User{} = user = Accounts.get_user!(params["user_id"])

    socket = assign(socket, %{
      user: user,
      sessions: Enum.sort_by(Labeling.list_sessions_with_progress(user), &(&1.session.inserted_at), {:desc, DateTime}),
      jobs: Labeling.list_label_jobs(user),
      pipelines: Assembly.list_pipelines_preloaded(user),

      tab: :sessions,
    })
    {:ok, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "sessions" -> :sessions
      "jobs" -> :jobs
      "pipelines" -> :pipelines
    end
    {:noreply, assign(socket, :tab, tab)}
  end
end
