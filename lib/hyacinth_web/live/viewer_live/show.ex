defmodule HyacinthWeb.ViewerLive.Show do
  use HyacinthWeb, :live_view
  alias Phoenix.PubSub

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.Object

  defmodule ViewerSelectForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :viewer, Ecto.Enum, values: [:web_image, :advanced_png], default: :advanced_png
    end

    @doc false
    def changeset(viewer_select_form, attrs) do
      viewer_select_form
      |> cast(attrs, [:viewer])
      |> validate_required([:viewer])
    end
  end

  def mount(%{"object_id" => object_id}, _session, socket) do
    socket = assign(socket, %{
      object: Warehouse.get_object!(object_id),
      viewer_select_changeset: ViewerSelectForm.changeset(%ViewerSelectForm{}, %{}),
    })
    {:ok, socket}
  end

  def handle_params(%{"viewer_session_id" => viewer_session_id}, _uri, socket) do
    if connected?(socket) do
      %Object{} = object = socket.assigns.object
      PubSub.subscribe(Hyacinth.PubSub, "viewer:#{object.id}:#{viewer_session_id}")
    end

    {:noreply, assign(socket, :viewer_session_id, viewer_session_id)}
  end

  def handle_params(params, _uri, socket) when not is_map_key(params, "viewer_session_id") do
    socket =
      if connected?(socket) do
        %Object{} = object = socket.assigns.object
        viewer_session_id = Ecto.UUID.generate()
        path = Routes.viewer_show_path(socket, :show_session, object.id, viewer_session_id)
        push_patch(socket, to: path, replace: true)
      else
        socket
      end
    {:noreply, socket}
  end

  def handle_event("form_change", %{"viewer_select_form" => params}, socket) do
    changeset = ViewerSelectForm.changeset(%ViewerSelectForm{}, params)
    socket = assign(socket, %{
      viewer_select_changeset: changeset,
    })
    {:noreply, socket}
  end

  def handle_event("viewer_state_updated", state, socket) do
    topic = "viewer:#{socket.assigns.object.id}:#{socket.assigns.viewer_session_id}"
    PubSub.broadcast_from!(Hyacinth.PubSub, self(), topic, {:viewer_updated, state})
    {:noreply, socket}
  end

  def handle_info({:viewer_updated, state}, socket) do
    socket = push_event(socket, "viewer_state_pushed", state)
    {:noreply, socket}
  end
end
