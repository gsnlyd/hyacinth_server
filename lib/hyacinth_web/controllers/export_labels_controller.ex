defmodule HyacinthWeb.ExportLabelsController do
  use HyacinthWeb, :controller

  alias Hyacinth.Labeling
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelSession, LabelElement, LabelEntry}

  def show(conn, %{"session_id" => session_id}) do
    csv = build_session_labels_csv(session_id)

    Phoenix.Controller.send_download(conn, {:binary, csv}, filename: "session_labels.csv", content_type: "text/plain", disposition: :inline)
  end

  @spec build_session_labels_csv(term) :: String.t
  defp build_session_labels_csv(session_id) do
    %LabelSession{} = session = Labeling.get_label_session_with_elements!(session_id)

    num_objects = length(hd(session.elements).objects)

    header_object_cols =
      1..num_objects
      |> Enum.map(fn i ->
        [
          "object_#{i}_name",
          "object_#{i}_hash",
        ]
      end)
      |> Enum.concat()

    header = [
      "element_index",
      "label_option",
      "started_at_timestamp",
      "completed_at_timestamp",
    ] ++ header_object_cols

    body =
      session.elements
      |> Enum.map(fn %LabelElement{} = element ->
        object_cols =
          element.objects
          |> Enum.map(fn %Object{} = object ->
            [
              object.name,
              object.hash,
            ]
          end)
          |> Enum.concat()

        element.labels
        |> Enum.map(fn %LabelEntry{} = label ->
          [
            element.element_index,
            label.value.option,
            label.metadata.started_at |> DateTime.to_unix() |> Integer.to_string(),
            label.metadata.completed_at |> DateTime.to_unix() |> Integer.to_string(),
          ] ++ object_cols
        end)
      end)
      |> Enum.concat()

    [header] ++ body
    |> Enum.map(fn row when is_list(row) -> Enum.join(row, ",") end)
    |> Enum.join("\n")
  end
end
