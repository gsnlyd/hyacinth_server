defmodule HyacinthWeb.LabelSessionLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling

  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelElement, LabelJobType}

  def mount(params, _session, socket) do
    label_session = Labeling.get_label_session_with_elements!(params["label_session_id"])

    socket = assign(socket, %{
      label_session: label_session,
      num_labeled: Enum.count(label_session.elements, &(length(&1.labels) > 0)),
      num_total: length(label_session.elements),
    })

    {:ok, socket}
  end
end
