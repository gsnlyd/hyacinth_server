defmodule HyacinthWeb.Components.ExportLabelsModal do
  use HyacinthWeb, :live_component

  alias Hyacinth.Labeling
  alias Hyacinth.Labeling.{LabelJob, LabelSession}

  defmodule ExportLabelsForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :include_labels, Ecto.Enum, values: [:all_labels, :only_final_labels], default: :only_final_labels
      field :timestamp_columns, Ecto.Enum, values: [:iso, :unix, :iso_and_unix], default: :iso
      field :object_columns, Ecto.Enum, values: [:names, :hashes, :names_and_hashes], default: :names
    end

    @doc false
    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:include_labels, :timestamp_columns, :object_columns])
      |> validate_required([:include_labels, :timestamp_columns, :object_columns])
    end
  end

  def update(%{session_id: session_id}, socket) do
    socket = assign(socket, %{
      job_or_session: Labeling.get_label_session!(session_id),
      changeset: ExportLabelsForm.changeset(%ExportLabelsForm{}, %{}),
    })
    {:ok, socket}
  end

  def update(%{job_id: job_id}, socket) do
    socket = assign(socket, %{
      job_or_session: Labeling.get_label_job!(job_id),
      changeset: ExportLabelsForm.changeset(%ExportLabelsForm{}, %{}),
    })
    {:ok, socket}
  end

  def handle_event("form_change", %{"export_labels_form" => params}, socket) do
    changeset = ExportLabelsForm.changeset(%ExportLabelsForm{}, params)
    {:noreply, assign(socket, :modal, {:export_labels, changeset})}
  end

  def handle_event("form_submit", %{"export_labels_form" => params}, socket) do
    changeset = ExportLabelsForm.changeset(%ExportLabelsForm{}, params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %ExportLabelsForm{} = struct} ->
        args = [
          include_labels: struct.include_labels,
          timestamp_columns: struct.timestamp_columns,
          object_columns: struct.object_columns,
        ]

        path =
          case socket.assigns.job_or_session do
            %LabelSession{} = session ->
              Routes.export_labels_path(socket, :export_session, session, args)
            %LabelJob{} = job ->
              Routes.export_labels_path(socket, :export_job, job, args)
          end
        {:noreply, redirect(socket, to: path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :modal, {:export_labels, changeset})}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal size="xs">
        <:header>Export Labels</:header>

        <div class="mt-2">
          <.form let={f} for={@changeset} phx-change="form_change" phx-submit="form_submit" phx-target={@myself}>
            <div class="form-content">
              <p>
                <%= label f, :include_labels %>
                <%= select f, :include_labels, humanize_enum(ExportLabelsForm, :include_labels) %>
                <%= error_tag f, :include_labels %>
              </p>

              <p>
                <%= label f, :timestamp_columns %>
                <%= select f, :timestamp_columns, [{"Date/Time (ISO)", :iso}, {"UNIX", :unix}, {"Date/Time (ISO) and UNIX", :iso_and_unix}] %>
                <%= error_tag f, :timestamp_columns %>
              </p>

              <p>
                <%= label f, :object_columns %>
                <%= select f, :object_columns, humanize_enum(ExportLabelsForm, :object_columns) %>
                <%= error_tag f, :object_columns %>
              </p>

              <%= submit "Export", class: "btn btn-blue" %>
            </div>
          </.form>
        </div>
      </.modal>
    </div>
    """
  end
end
