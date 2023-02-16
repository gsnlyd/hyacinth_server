defmodule HyacinthWeb.ResultsLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling

  alias Hyacinth.Labeling.{LabelSession, LabelJobType}

  defmodule ResultsDisplayForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :order, Ecto.Enum, values: [:ascending, :descending], default: :descending
    end

    @doc false
    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:order])
      |> validate_required([:order])
    end
  end

  defmodule ExportResultsForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :object_columns, Ecto.Enum, values: [:names, :hashes, :names_and_hashes], default: :names
    end

    @doc false
    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:object_columns])
      |> validate_required([:object_columns])
    end
  end

  def mount(%{"label_session_id" => label_session_id}, _session, socket) do
    label_session = Labeling.get_label_session_with_elements!(label_session_id)
    job = Labeling.get_job_with_blueprint(label_session.job_id)

    results_objects = LabelJobType.session_results(job.type, job.options, job, label_session)

    socket = assign(socket, %{
      label_session: label_session,
      job: job,
      results_objects: results_objects,

      display_changeset: ResultsDisplayForm.changeset(%ResultsDisplayForm{}, %{}),
      columns: 4,

      modal: nil,
    })
    {:ok, socket}
  end

  def mount(%{"label_job_id" => label_job_id}, _session, socket) do
    job = Labeling.get_job_with_blueprint(label_job_id)
    label_sessions = Labeling.list_sessions_preloaded(job)

    results_objects = LabelJobType.job_results(job.type, job.options, job, label_sessions)

    socket = assign(socket, %{
      job: job,
      label_sessions: label_sessions,
      results_objects: results_objects,

      display_changeset: ResultsDisplayForm.changeset(%ResultsDisplayForm{}, %{}),
      columns: 4,

      modal: nil,
    })
    {:ok, socket}
  end

  defp order_results(display_changeset, results_objects) do
    %ResultsDisplayForm{} = form = Ecto.Changeset.apply_changes(display_changeset)
    case form.order do
      :ascending ->
        results_objects

      :descending ->
        Enum.reverse(results_objects)
    end
  end

  defp grid_cols_class(columns) do
    case columns do
      2 -> "grid-cols-2"
      4 -> "grid-cols-4"
      8 -> "grid-cols-8"
    end
  end

  def handle_event("display_form_change", %{"results_display_form" => params}, socket) do
    changeset = ResultsDisplayForm.changeset(%ResultsDisplayForm{}, params)
    {:noreply, assign(socket, :display_changeset, changeset)}
  end

  def handle_event("set_columns", %{"columns" => columns}, socket) do
    columns = String.to_integer(columns)
    {:noreply, assign(socket, :columns, columns)}
  end

  def handle_event("open_modal_export_results", _params, socket) do
    changeset = ExportResultsForm.changeset(%ExportResultsForm{}, %{})
    {:noreply, assign(socket, :modal, {:export_results, changeset})}
  end

  def handle_event("export_results_change", %{"export_results_form" => params}, socket) do
    changeset = ExportResultsForm.changeset(%ExportResultsForm{}, params)
    {:noreply, assign(socket, :modal, {:export_results, changeset})}
  end

  def handle_event("export_results_submit", %{"export_results_form" => params}, socket) do
    changeset = ExportResultsForm.changeset(%ExportResultsForm{}, params)
    case Ecto.Changeset.apply_action!(changeset, :insert) do
      %ExportResultsForm{} = struct ->
        args = [
          object_columns: struct.object_columns,
        ]

        path =
          case socket.assigns[:label_session] do
            %LabelSession{} ->
              Routes.export_results_path(socket, :export_session, socket.assigns.label_session, args)
            nil ->
              Routes.export_results_path(socket, :export_job, socket.assigns.job, args)
          end
        {:noreply, redirect(socket, to: path)}

      %Ecto.Changeset{} = changeset ->
        {:noreply, assign(socket, :modal, {:export_results, changeset})}
    end
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :modal, nil)}
  end
end
