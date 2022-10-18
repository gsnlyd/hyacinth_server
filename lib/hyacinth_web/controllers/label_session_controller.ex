defmodule HyacinthWeb.LabelSessionController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Labeling}

  def new(conn, %{"label_job_id" => label_job_id}) do
    label_job = Labeling.get_label_job!(label_job_id)
    label_session = Labeling.create_label_session(label_job, conn.assigns.current_user)

    redirect(conn, to: Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Show, label_session))
  end
end
