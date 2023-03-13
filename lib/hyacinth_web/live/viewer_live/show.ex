defmodule HyacinthWeb.ViewerLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, ViewerState}
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

  @initial_state %{
    "minThreshold" => 0,
    "maxThreshold" => 255,
  }

  def mount(%{"object_id" => object_id}, _session, socket) do
    socket = assign(socket, %{
      object: Warehouse.get_object!(object_id),
      viewer_select_changeset: ViewerSelectForm.changeset(%ViewerSelectForm{}, %{}),

      viewer_state: @initial_state,
      session_owner: false,
    })
    {:ok, socket}
  end

  def handle_params(%{"viewer_session_id" => viewer_session_id}, _uri, socket) do
    socket =
      if connected?(socket) do
        if ViewerState.exists?(viewer_session_id) do
          ViewerState.subscribe(viewer_session_id)
          socket
          |> assign(:viewer_state, ViewerState.get_state(viewer_session_id))
          |> push_state_to_client()
        else
          path = Routes.viewer_show_path(socket, :new_session, socket.assigns.object.id)
          redirect(socket, to: path)
        end
      else
        socket
      end

    {:noreply, assign(socket, :viewer_session_id, viewer_session_id)}
  end

  def handle_params(params, _uri, socket) when not is_map_key(params, "viewer_session_id") do
    socket =
      if connected?(socket) do
        %Object{} = object = socket.assigns.object
        viewer_session_id = Ecto.UUID.generate()

        ViewerState.start_link(socket.assigns.viewer_state, viewer_session_id)

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
    push_event(socket, "viewer_state_pushed", socket.assigns.viewer_state)
  end

  def handle_event("form_change", %{"viewer_select_form" => params}, socket) do
    changeset = ViewerSelectForm.changeset(%ViewerSelectForm{}, params)
    socket = assign(socket, %{
      viewer_select_changeset: changeset,
    })
    {:noreply, socket}
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
end
