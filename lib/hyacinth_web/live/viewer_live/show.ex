defmodule HyacinthWeb.ViewerLive.Show do
  use HyacinthWeb, :live_view

  alias HyacinthWeb.Presence

  alias Hyacinth.{Warehouse, ViewerState}
  alias Hyacinth.Warehouse.Object

  def mount(%{"object_id" => object_id}, _session, socket) do
    socket = assign(socket, %{
      object: Warehouse.get_object!(object_id),

      viewer_state: %{},
      session_owner: false,
      user_list: [],
    })
    {:ok, socket}
  end

  def handle_params(%{"viewer_session_id" => viewer_session_id}, _uri, socket) do
    socket =
      if connected?(socket) do
        if ViewerState.exists?(viewer_session_id) do
          ViewerState.subscribe(viewer_session_id)

          current_user = socket.assigns.current_user
          {:ok, _} = Presence.track(self(), presence_topic(viewer_session_id), current_user.id, %{
            user_name: current_user.name,
          })
          Phoenix.PubSub.subscribe(Hyacinth.PubSub, presence_topic(viewer_session_id))

          socket
          |> assign(:viewer_session_id, viewer_session_id)
          |> assign(:viewer_state, ViewerState.get_state(viewer_session_id))
          |> push_state_to_client()
          |> update_user_list()
        else
          path = Routes.viewer_show_path(socket, :new_session, socket.assigns.object.id)
          redirect(socket, to: path)
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_params(params, _uri, socket) when not is_map_key(params, "viewer_session_id") do
    socket =
      if connected?(socket) do
        %Object{} = object = socket.assigns.object
        viewer_session_id = Ecto.UUID.generate()

        ViewerState.start_link(%{}, viewer_session_id)

        path = Routes.viewer_show_path(socket, :show_session, object.id, viewer_session_id)
        socket
        |> assign(:session_owner, true)
        |> push_patch(to: path, replace: true)
      else
        socket
      end
    {:noreply, socket}
  end

  def push_state_to_client(socket) do
    data = %{
      state: socket.assigns.viewer_state,
      uniqueId: 0,
    }
    push_event(socket, "viewer_state_pushed", data)
  end

  def presence_topic(viewer_session_id), do: "viewer_presence:#{viewer_session_id}"

  def update_user_list(socket) do
    user_list =
      socket.assigns.viewer_session_id
      |> presence_topic()
      |> Presence.list()
      |> Enum.map(fn {_k, v} ->
        user_meta = hd(v.metas)
        Map.put(user_meta, :count, length(v.metas))
      end)

    assign(socket, :user_list, user_list)
  end

  def handle_event("viewer_state_initialized", state, socket) do
    if socket.assigns.session_owner do
      viewer_state = ViewerState.merge_state(socket.assigns.viewer_session_id, state)
      {:noreply, assign(socket, :viewer_state, viewer_state)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("viewer_state_updated", state, socket) do
    viewer_state = ViewerState.merge_state(socket.assigns.viewer_session_id, state)
    {:noreply, assign(socket, :viewer_state, viewer_state)}
  end

  def handle_info({:viewer_updated, state}, socket) do
    socket =
      socket
      |> assign(:viewer_state, state)
      |> push_state_to_client()
    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, update_user_list(socket)}
  end
end
