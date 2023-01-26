defmodule HyacinthWeb.LabelSessionLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling

  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelElement, LabelJobType}

  defmodule ExportLabelsForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :include_labels, Ecto.Enum, values: [:all_labels, :only_final_labels], default: :all_labels
      field :timestamp_columns, Ecto.Enum, values: [:iso, :unix, :iso_and_unix], default: :iso_and_unix
      field :object_columns, Ecto.Enum, values: [:names, :hashes, :names_and_hashes], default: :names_and_hashes
    end

    @doc false
    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:include_labels, :timestamp_columns, :object_columns])
      |> validate_required([:include_labels, :timestamp_columns, :object_columns])
    end
  end

  def mount(params, _session, socket) do
    label_session = Labeling.get_label_session_with_elements!(params["label_session_id"])

    socket = assign(socket, %{
      label_session: label_session,
      num_labeled: Enum.count(label_session.elements, &(length(&1.labels) > 0)),
      num_total: length(label_session.elements),

      modal: nil,
    })

    {:ok, socket}
  end

  def handle_event("open_modal_export_labels", _value, socket) do
    changeset = ExportLabelsForm.changeset(%ExportLabelsForm{}, %{})
    {:noreply, assign(socket, :modal, {:export_labels, changeset})}
  end

  def handle_event("export_labels_change", %{"export_labels_form" => params}, socket) do
    changeset = ExportLabelsForm.changeset(%ExportLabelsForm{}, params)
    {:noreply, assign(socket, :modal, {:export_labels, changeset})}
  end

  def handle_event("export_labels_submit", %{"export_labels_form" => params}, socket) do
    changeset = ExportLabelsForm.changeset(%ExportLabelsForm{}, params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %ExportLabelsForm{} = struct} ->
        args = [
          include_labels: struct.include_labels,
          timestamp_columns: struct.timestamp_columns,
          object_columns: struct.object_columns,
        ]
        path = Routes.export_labels_path(socket, :show, socket.assigns.label_session, args)
        {:noreply, redirect(socket, to: path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :modal, {:export_labels, changeset})}
    end
  end

  def handle_event("close_modal", _value, socket)  do
    {:noreply, assign(socket, :modal, nil)}
  end
end
