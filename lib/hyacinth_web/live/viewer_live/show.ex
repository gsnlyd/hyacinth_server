defmodule HyacinthWeb.ViewerLive.Show do
  use HyacinthWeb, :live_view
  alias Phoenix.PubSub

  alias Hyacinth.Warehouse

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


  def mount(params, _session, socket) do
    viewer_session_id = params["viewer_session_id"]
    if viewer_session_id do
      object = Warehouse.get_object!(params["object_id"])
      if connected?(socket), do: PubSub.subscribe(Hyacinth.PubSub, "viewer:#{object.id}:#{viewer_session_id}")

      socket = assign(socket, %{
        object: object,
        viewer_select_changeset: ViewerSelectForm.changeset(%ViewerSelectForm{}, %{}),

        viewer_session_id: viewer_session_id,

        import_viewer_scripts: true,
      })
      {:ok, socket}
    else
      viewer_session_id = Ecto.UUID.generate()
      path = Routes.live_path(socket, HyacinthWeb.ViewerLive.Show, params["object_id"], viewer_session_id)
      {:ok, push_redirect(socket, to: path)}
    end
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
