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

  def handle_event("set_label_key", %{"key" => key}, socket) when key in ["1", "2", "3", "4", "5", "6", "7", "8", "9"] do
    label_i = String.to_integer(key) - 1
    label_value = Enum.at(socket.assigns.label_session.job.label_options, label_i)
    case label_value do
      label_value when is_binary(label_value) ->
        Labeling.create_label_entry!(socket.assigns.element, socket.assigns.current_user, label_value)

        labels = Labeling.list_element_labels(socket.assigns.element)
        socket = assign(socket, %{
          labels: labels,
          current_value: hd(labels).label_value,
        })
        {:noreply, socket}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("set_label_key", _value, socket), do: {:noreply, socket}

  def handle_event("prev_element", _value, socket) do
    new_index = max(socket.assigns.element.element_index - 1, 0)
    path = Routes.live_path(socket, HyacinthWeb.LabelSessionLive.Label, socket.assigns.label_session, new_index)
    {:noreply, push_redirect(socket, to: path)}
  end

  def handle_event("next_element", _value, socket) do
    new_index = min(socket.assigns.element.element_index + 1, length(socket.assigns.label_session.elements) - 1)
    path = Routes.live_path(socket, HyacinthWeb.LabelSessionLive.Label, socket.assigns.label_session, new_index)
    {:noreply, push_redirect(socket, to: path)}
  end
end
