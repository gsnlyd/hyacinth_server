defmodule HyacinthWeb.ExportLabelsController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Labeling, Utils}
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelSession, LabelElement, LabelEntry}

  def export_session(conn, %{"session_id" => session_id} = params) do
    session  = Labeling.get_label_session_with_elements!(session_id)
    export(conn, params, [session])
  end

  def export_job(conn, %{"job_id" => job_id} = params) do
    job = Labeling.get_label_job!(job_id)
    sessions = Labeling.list_sessions_preloaded(job)
    export(conn, params, sessions)
  end

  def export(conn, params, sessions) do
    args = [
      all_labels:       params["include_labels"] == "all_labels",
      iso_timestamps:   params["timestamp_columns"] in ["iso", "iso_and_unix"],
      unix_timestamps:  params["timestamp_columns"] in ["unix", "iso_and_unix"],
      object_names:     params["object_columns"] in ["names", "names_and_hashes"],
      object_hashes:    params["object_columns"] in ["hashes", "names_and_hashes"],
    ]

    csv =
      sessions
      |> build_labels_csv(args)
      |> Utils.rows_to_csv_string()

    Phoenix.Controller.send_download(conn, {:binary, csv}, filename: "session_labels.csv", content_type: "text/plain", disposition: :inline)
  end

  @spec build_labels_csv([%LabelSession{}], keyword) :: [[String.t]]
  defp build_labels_csv(sessions, args) do
    num_objects = if length(sessions) == 0, do: 1, else: length(hd(hd(sessions).elements).objects)

    header_object_cols =
      1..num_objects
      |> Enum.map(fn i ->
        [
          if(args[:object_names], do: "object_#{i}_name"),
          if(args[:object_hashes], do: "object_#{i}_hash"),
        ]
      end)
      |> Enum.concat()

    header = [
      "user_id",
      "user_name",
      "element_index",
      "label_option",
      if(args[:iso_timestamps], do: "started_at_iso"),
      if(args[:unix_timestamps], do: "started_at_unix_ms"),
      if(args[:iso_timestamps], do: "completed_at_iso"),
      if(args[:unix_timestamps], do: "completed_at_unix_ms"),
    ] ++ header_object_cols

    body =
      sessions
      |> Enum.map(fn %LabelSession{} = session ->
        Enum.map(session.elements, fn element -> {session, element} end)
      end)
      |> Enum.concat()
      |> Enum.map(fn {%LabelSession{} = session, %LabelElement{} = element} ->
        object_cols =
          element.objects
          |> Enum.map(fn %Object{} = object ->
            [
              if(args[:object_names], do: object.name),
              if(args[:object_hashes], do: object.hash),
            ]
          end)
          |> Enum.concat()

        labels =
          if args[:all_labels] do
            element.labels
          else
            if length(element.labels) > 0, do: [hd(element.labels)], else: []
          end

        labels
        |> Enum.map(fn %LabelEntry{} = label ->
          [
            session.user_id,
            session.user.name,
            element.element_index,
            label.value.option,
            if(args[:iso_timestamps], do: label.metadata.started_at |> Calendar.strftime("%c")),
            if(args[:unix_timestamps], do: label.metadata.started_at |> DateTime.to_unix(:millisecond) |> Integer.to_string()),
            if(args[:iso_timestamps], do: label.metadata.completed_at |> Calendar.strftime("%c")),
            if(args[:unix_timestamps], do: label.metadata.completed_at |> DateTime.to_unix(:millisecond) |> Integer.to_string()),
          ] ++ object_cols
        end)
      end)
      |> Enum.concat()

    [header] ++ body
  end
end
