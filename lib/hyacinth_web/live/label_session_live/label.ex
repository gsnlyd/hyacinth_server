defmodule HyacinthWeb.LabelSessionLive.Label do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling

  def mount(params, _session, socket) do
    label_session = Labeling.get_label_session_with_elements!(params["label_session_id"])
    element = Labeling.get_label_element!(label_session, params["element_index"])
    labels = Labeling.list_element_labels(element)

    socket = assign(socket, %{
      label_session: label_session,
      element: element,
      labels: labels,

      current_value: if(length(labels) == 0, do: nil, else: hd(labels).label_value),

      disable_primary_nav: true,
      use_wide_layout: true,
    })

    {:ok, socket}
  end

  def handle_event("set_label", %{"label" => label_value}, socket) do
    Labeling.create_label_entry!(socket.assigns.element, socket.assigns.current_user, label_value)

    labels = Labeling.list_element_labels(socket.assigns.element)
    socket = assign(socket, %{
      labels: labels,
      current_value: hd(labels).label_value,
    })
    {:noreply, socket}
  end
end
