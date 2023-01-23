defmodule HyacinthWeb.ExportLabelsController do
  use HyacinthWeb, :controller

  alias Hyacinth.Labeling
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelSession, LabelElement, LabelEntry}

  def show(conn, %{"session_id" => session_id} = params) do
    args =  [
      iso_timestamps:   params["timestamp_columns"] in ["iso", "iso_and_unix"],
      unix_timestamps:  params["timestamp_columns"] in ["unix", "iso_and_unix"],
      object_names:     params["object_columns"] in ["names", "names_and_hashes"],
      object_hashes:    params["object_columns"] in ["hashes", "names_and_hashes"],
    ]

    csv =
      session_id
      |> build_session_labels_csv(args)
      |> rows_to_string()

    Phoenix.Controller.send_download(conn, {:binary, csv}, filename: "session_labels.csv", content_type: "text/plain", disposition: :inline)
  end

  @spec build_session_labels_csv(term, keyword) :: [[String.t]]
  defp build_session_labels_csv(session_id, args) do
    %LabelSession{} = session = Labeling.get_label_session_with_elements!(session_id)

    num_objects = length(hd(session.elements).objects)

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
      "element_index",
      "label_option",
      if(args[:iso_timestamps], do: "started_at_iso"),
      if(args[:unix_timestamps], do: "started_at_unix"),
      if(args[:iso_timestamps], do: "completed_at_iso"),
      if(args[:unix_timestamps], do: "completed_at_unix"),
    ] ++ header_object_cols

    body =
      session.elements
      |> Enum.map(fn %LabelElement{} = element ->
        object_cols =
          element.objects
          |> Enum.map(fn %Object{} = object ->
            [
              if(args[:object_names], do: object.name),
              if(args[:object_hashes], do: object.hash),
            ]
          end)
          |> Enum.concat()

        element.labels
        |> Enum.map(fn %LabelEntry{} = label ->
          [
            element.element_index,
            label.value.option,
            if(args[:iso_timestamps], do: label.metadata.started_at |> Calendar.strftime("%c")),
            if(args[:unix_timestamps], do: label.metadata.started_at |> DateTime.to_unix() |> Integer.to_string()),
            if(args[:iso_timestamps], do: label.metadata.completed_at |> Calendar.strftime("%c")),
            if(args[:unix_timestamps], do: label.metadata.completed_at |> DateTime.to_unix() |> Integer.to_string()),
          ] ++ object_cols
        end)
      end)
      |> Enum.concat()

    [header] ++ body
  end

  @spec rows_to_string([[String.t]]) :: String.t
  defp rows_to_string(rows) when is_list(rows) do
    rows
    |> Enum.map(fn row when is_list(row) ->
      row
      |> Enum.filter(&(&1 != nil))
      |> Enum.join(",")
    end)
    |> Enum.join("\n")
  end
end
