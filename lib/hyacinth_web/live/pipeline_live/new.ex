defmodule HyacinthWeb.PipelineLive.New do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Accounts, Warehouse, Assembly}
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  def mount(_params, session, socket) do
    socket = assign(socket, %{
      datasets: Warehouse.list_datasets(),
      pipeline_changeset: Ecto.Changeset.change(%Pipeline{}, %{name: "My Pipeline"}), # TODO: remove default name
      transforms: [],

      # TODO: move this to an on_mount
      current_user: Accounts.get_user_by_session_token(session["user_token"]),
    })

    {:ok, socket}
  end

  def handle_event("save_pipeline", _value, socket) do
    name = Ecto.Changeset.get_field(socket.assigns.pipeline_changeset, :name)
    dataset_id = Ecto.Changeset.get_field(socket.assigns.pipeline_changeset, :dataset_id)
    Assembly.create_pipeline(socket.assigns.current_user, name, dataset_id, socket.assigns.transforms)

    {:noreply, socket}
  end

  def handle_event("validate_pipeline", %{"pipeline" => pipeline_params}, socket) do
    changeset =
      %Pipeline{}
      |> Pipeline.changeset(pipeline_params)
      |> Map.put(:action, :insert)

    socket = assign(socket, :pipeline_changeset, changeset)
    {:noreply, socket}
  end

  def handle_event("add_transform", _value, socket) do
    new_index = length(socket.assigns.transforms)

    transform_changeset =
      %Transform{order_index: new_index}
      |> Assembly.change_transform()
      |> Map.put(:action, :insert)
    options_changeset = Driver.options_changeset(transform_changeset.data.driver)

    transforms = socket.assigns.transforms ++ [{transform_changeset, options_changeset}]
    socket = assign(socket, :transforms, transforms)

    {:noreply, socket}
  end

  def handle_event("remove_last_transform", _value, socket) do
    socket = assign(socket, :transforms, List.delete_at(socket.assigns.transforms, -1))
    {:noreply, socket}
  end

  def handle_event("validate_transform", %{"transform" => transform_params}, socket) do
    transform_changeset = Assembly.change_transform(%Transform{}, transform_params)
    options_changeset = Driver.options_changeset(Ecto.Changeset.get_field(transform_changeset, :driver))

    index = Ecto.Changeset.get_change(transform_changeset, :order_index)
    transforms = List.replace_at(socket.assigns.transforms, index, {transform_changeset, options_changeset})
    socket = assign(socket, :transforms, transforms)

    {:noreply, socket}
  end

  def handle_event("validate_transform_options", %{"options" => options_pararms}, socket) do
    transform_index = String.to_integer(options_pararms["transform_index"])
    {transform_changeset, _} = Enum.at(socket.assigns.transforms, transform_index)

    options_changeset =
      transform_changeset
      |> Ecto.Changeset.get_field(:driver)
      |> Driver.options_changeset(options_pararms)
      |> Map.put(:action, :insert)

    transforms = List.replace_at(socket.assigns.transforms, transform_index, {transform_changeset, options_changeset})
    socket = assign(socket, :transforms, transforms)

    {:noreply, socket}
  end
end
