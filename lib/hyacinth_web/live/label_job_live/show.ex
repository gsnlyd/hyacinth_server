defmodule HyacinthWeb.LabelJobLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling

  def mount(params, _session, socket) do
    job = Labeling.get_label_job!(params["label_job_id"])
    socket = assign(socket, %{
      job: job,
      sessions: Labeling.list_job_sessions(job)
    })
    {:ok, socket}
  end
end
