defmodule HyacinthWeb.LabelSessionLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling

  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelElement}

  def mount(params, _session, socket) do
    label_session = Labeling.get_label_session_with_elements!(params["label_session_id"])

    socket = assign(socket, %{
      label_session: label_session,
    })

    {:ok, socket}
  end
end
