defmodule HyacinthWeb.ExportResultsController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Labeling, Utils}

  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.LabelJobType

  def export_session(conn, %{"session_id" => session_id} = params) do
    label_session = Labeling.get_label_session_with_elements!(session_id)
    job = Labeling.get_job_with_blueprint(label_session.job_id)

    results_objects = LabelJobType.session_results(job.type, job.options, job, label_session)
    export(conn, params, results_objects)
  end

  def export_job(conn, %{"job_id" => job_id} = params) do
    job = Labeling.get_job_with_blueprint(job_id)
    label_sessions = Labeling.list_sessions_preloaded(job)

    results_objects = LabelJobType.job_results(job.type, job.options, job, label_sessions)
    export(conn, params, results_objects)
  end

  def export(conn, params, results_objects) do
    args = [
      object_names:  params["object_columns"] in ["names", "names_and_hashes"],
      object_hashes: params["object_columns"] in ["hashes", "names_and_hashes"],
    ]

    csv =
      results_objects
      |> build_csv(args)
      |> Utils.rows_to_csv_string()

    Phoenix.Controller.send_download(conn, {:binary, csv}, filename: "results.csv", content_type: "text/plain", disposition: :inline)
  end

  @spec build_csv([{%Object{}, String.t}], keyword) :: [[String.t]]
  defp build_csv(resuls_objects, args) do
    header = [
      "index",
      if(args[:object_names], do: "object_name"),
      if(args[:object_hashes], do: "object_hash"),
      "details",
    ]

    rows =
      resuls_objects
      |> Enum.with_index()
      |> Enum.map(fn {{%Object{} = object, details}, i} ->
        [
          Integer.to_string(i),
          if(args[:object_names], do: object.name),
          if(args[:object_hashes], do: object.hash),
          details,
        ]
      end)

    [header] ++ rows
  end
end
