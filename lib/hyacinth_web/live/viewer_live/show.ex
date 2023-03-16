defmodule HyacinthWeb.ViewerLive.Show do
  use HyacinthWeb, :live_view

  alias HyacinthWeb.Presence

  alias Hyacinth.{Warehouse, ViewerState}

  defmodule ObjectForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :dataset_id, :integer
      field :object_id, :integer
    end

    @doc false
    def changeset(object_form, attrs) do
      object_form
      |> cast(attrs, [:dataset_id, :object_id])
      |> validate_required([:dataset_id, :object_id])
    end
  end

  @initial_state %{
    "minThreshold" => 0,
    "maxThreshold" => 255,
  }

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      dataset: nil,
      object: nil,
      datasets: [],
      objects: [],
      object_form_changeset: ObjectForm.changeset(%ObjectForm{}, %{}),

      session_owner: false,
      user_list: [%{user_name: socket.assigns.current_user.name, count: 1}],

      use_wide_layout: true,
    })
    {:ok, socket}
  end

  def handle_params(%{"viewer_session_id" => viewer_session_id}, _uri, socket) do
    if ViewerState.exists?(viewer_session_id) do
      if connected?(socket) do
        ViewerState.subscribe(viewer_session_id)

        current_user = socket.assigns.current_user
        {:ok, _} = Presence.track(self(), presence_topic(viewer_session_id), current_user.id, %{
          user_name: current_user.name,
        })
        Phoenix.PubSub.subscribe(Hyacinth.PubSub, presence_topic(viewer_session_id))
      end

      viewer_state = ViewerState.get_state(viewer_session_id)

      dataset = Warehouse.get_dataset!(viewer_state["dataset_id"])
      object = Warehouse.get_object!(viewer_state["object_id"])

      socket = assign(socket, %{
        dataset: dataset,
        object: object,

        datasets: Warehouse.list_datasets(),
        objects: Warehouse.list_objects(dataset),

        object_form_changeset: ObjectForm.changeset(%ObjectForm{}, %{"dataset_id" => dataset.id, "object_id" => object.id}),

        viewer_state: viewer_state,
      })

      socket =
        socket
        |> assign(:viewer_session_id, viewer_session_id)
        |> assign(:viewer_state, ViewerState.get_state(viewer_session_id))
        |> push_state_to_client()
        |> update_user_list()

      {:noreply, socket}
    else
      path = Routes.viewer_show_path(socket, :new_session)
      {:noreply, redirect(socket, to: path)}
    end
  end

  def handle_params(params, _uri, socket) when not is_map_key(params, "viewer_session_id") do
    socket =
      if connected?(socket) do
        viewer_session_id = Ecto.UUID.generate()

        {dataset, object} =
          case params do
            %{"dataset" => dataset_id, "object" => object_id} ->
              {Warehouse.get_dataset!(dataset_id), Warehouse.get_object!(object_id)}
            _ ->
              dataset = hd(Warehouse.list_datasets())
              object = hd(Warehouse.list_objects(dataset))
              {dataset, object}
          end

        initial_state = Map.merge(@initial_state, %{"object_id" => object.id, "dataset_id" => dataset.id})
        ViewerState.start_link(initial_state, viewer_session_id)

        path = Routes.viewer_show_path(socket, :show_session, viewer_session_id)
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
      uniqueId: "#{socket.assigns.object.id}",
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

  def update_object(socket, params) do
    changeset = ObjectForm.changeset(%ObjectForm{}, params)

    dataset_id = Ecto.Changeset.get_field(changeset, :dataset_id)
    params_object_id = Ecto.Changeset.get_field(changeset, :object_id)

    dataset = Warehouse.get_dataset!(dataset_id)
    objects = Warehouse.list_objects(dataset)

    # If selected object is not in dataset, reset to first object in dataset
    changeset =
      if Enum.any?(objects, fn o -> o.id == params_object_id end) do
        changeset
      else
        Ecto.Changeset.put_change(changeset, :object_id, hd(objects).id)
      end

    object = Warehouse.get_object!(Ecto.Changeset.get_field(changeset, :object_id))

    assign(socket, %{
      object_form_changeset: changeset,

      objects: Warehouse.list_objects(dataset),
      dataset: dataset,
      object: object,
    })
  end

  def handle_event("object_form_change", %{"object_form" => params}, socket) do
    socket = update_object(socket, params)

    viewer_state =
      socket.assigns.viewer_state
      |> Map.put("dataset_id", socket.assigns.dataset.id)
      |> Map.put("object_id", socket.assigns.object.id)

    socket = assign(socket, :viewer_state, viewer_state)
    ViewerState.merge_state(socket.assigns.viewer_session_id, socket.assigns.viewer_state)

    socket = push_state_to_client(socket)

    {:noreply, socket}
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
      |> update_object(%{"dataset_id" => state["dataset_id"], "object_id" => state["object_id"]})
      |> push_state_to_client()
    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, update_user_list(socket)}
  end
end
