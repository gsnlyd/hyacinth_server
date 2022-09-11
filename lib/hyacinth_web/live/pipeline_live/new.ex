defmodule HyacinthWeb.PipelineLive.New do
  use HyacinthWeb, :live_view

  alias Hyacinth.Assembly
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      pipeline_changeset: Ecto.Changeset.change(%Pipeline{}),
      transforms: [],
    })

    {:ok, socket}
  end

  def handle_event("validate_pipeline", %{"pipeline" => pipeline_params}, socket) do
    IO.inspect pipeline_params
    changeset =
      %Pipeline{}
      |> Pipeline.changeset(pipeline_params)
      |> Map.put(:action, :insert)
    IO.inspect changeset

    socket = assign(socket, :pipeline_changeset, changeset)
    {:noreply, socket}
  end

  def handle_event("add_transform", _value, socket) do
    transform_changeset = Assembly.change_transform(%Transform{})
    options_changeset = Driver.options_changeset(transform_changeset.data.driver)

    transforms = socket.assigns.transforms ++ [{transform_changeset, options_changeset}]
    socket = assign(socket, :transforms, transforms)

    {:noreply, socket}
  end

  def handle_event("remove_transform", %{"transform-index" => transform_index}, socket) do
    transform_index = String.to_integer(transform_index)
    transforms = List.delete_at(socket.assigns.transforms, transform_index)
    socket = assign(socket, :transforms, transforms)
    {:noreply, socket}
  end
end
