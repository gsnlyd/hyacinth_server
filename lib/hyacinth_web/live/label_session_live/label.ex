defmodule HyacinthWeb.LabelSessionLive.Label do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling
  alias Hyacinth.Labeling.Note

  defmodule ViewerSelectForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :viewer, Ecto.Enum, values: [:basic, :advanced], default: :advanced
    end

    @doc false
    def changeset(viewer_select_form, attrs) do
      viewer_select_form
      |> cast(attrs, [:viewer])
      |> validate_required([:viewer])
    end
  end

  def mount(params, _session, socket) do
    label_session = Labeling.get_label_session_with_elements!(params["label_session_id"])
    element = Labeling.get_label_element!(label_session, params["element_index"])
    labels = Labeling.list_element_labels(element)

    socket = assign(socket, %{
      label_session: label_session,
      element: element,
      labels: labels,

      current_value: if(length(labels) == 0, do: nil, else: hd(labels).value.option),

      viewer_select_changeset: ViewerSelectForm.changeset(%ViewerSelectForm{}, %{}),

      modal: nil,

      disable_primary_nav: true,
      use_wide_layout: true,
      import_viewer_scripts: true,
    })

    {:ok, socket}
  end

  def handle_event("set_label", %{"label" => label_value}, socket) do
    Labeling.create_label_entry!(socket.assigns.element, socket.assigns.current_user, label_value)

    labels = Labeling.list_element_labels(socket.assigns.element)
    socket = assign(socket, %{
      labels: labels,
      current_value: hd(labels).value.option,
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
          current_value: hd(labels).value.option,
        })
        {:noreply, socket}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("set_label_key", _value, socket), do: {:noreply, socket}

  def handle_event("note_change", %{"note" => params}, socket) do
    changeset =
      (socket.assigns.element.note || %Note{})
      |> Note.changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :modal, {:notes, changeset})}
  end

  def handle_event("note_submit", %{"note" => params}, socket) do
    case socket.assigns.element.note do
      nil ->
        case Labeling.create_note(socket.assigns.current_user, socket.assigns.element, params) do
          {:ok, _values} ->
            socket = assign(socket, %{
              element: Labeling.get_label_element!(socket.assigns.label_session, socket.assigns.element.element_index),
              modal: nil,
            })
            {:noreply, socket}

          {:error, :note, %Ecto.Changeset{} = changeset, _changes} ->
            {:noreply, assign(socket, :modal, {:notes, changeset})}
        end

      %Note{} = existing_note ->
        case Labeling.update_note(socket.assigns.current_user, existing_note, params) do
          {:ok, _values} ->
            socket = assign(socket, %{
              element: Labeling.get_label_element!(socket.assigns.label_session, socket.assigns.element.element_index),
              modal: nil,
            })
            {:noreply, socket}

          {:error, :note, %Ecto.Changeset{} = changeset, _changes} ->
            {:noreply, assign(socket, :modal, {:notes, changeset})}
        end
    end
  end

  def handle_event("viewer_change", %{"viewer_select_form" => params}, socket) do
    changeset = ViewerSelectForm.changeset(%ViewerSelectForm{}, params)
    {:noreply, assign(socket, :viewer_select_changeset, changeset)}
  end

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

  def handle_event("open_modal_label_history", _value, socket) do
    {:noreply, assign(socket, :modal, :label_history)}
  end

  def handle_event("open_modal_notes", _value, socket) do
    changeset = Note.changeset(socket.assigns.element.note || %Note{}, %{})
    {:noreply, assign(socket, :modal, {:notes, changeset})}
  end

  def handle_event("close_modal", _value, socket) do
    {:noreply, assign(socket, :modal, nil)}
  end
end
