defmodule HyacinthWeb.ResultsLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling

  alias Hyacinth.Labeling.LabelJobType

  def mount(params, _session, socket) do
    label_session = Labeling.get_label_session_with_elements!(params["label_session_id"])
    job = Labeling.get_job_with_blueprint(label_session.job_id)

    results_objects = LabelJobType.session_results(job.type, job.options, job, label_session)

    socket = assign(socket, %{
      label_session: label_session,
      job: job,
      results_objects: results_objects,
    })
    {:ok, socket}
  end
end
