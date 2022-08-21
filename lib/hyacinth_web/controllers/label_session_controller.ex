defmodule HyacinthWeb.LabelSessionController do
  use HyacinthWeb, :controller

  alias Hyacinth.{Labeling}

  def new(conn, %{"label_job_id" => label_job_id}) do
    label_job = Labeling.get_label_job!(label_job_id)
    label_session = Labeling.create_label_session(label_job, conn.assigns.current_user)

    redirect(conn, to: Routes.label_session_path(conn, :show, label_session))
  end

  def show(conn, %{"label_session_id" => label_session_id}) do
    label_session = Labeling.get_label_session_with_elements!(label_session_id)

    render(conn, "show.html", label_session: label_session)
  end

  def index(conn, %{"label_session_id" => label_session_id, "element_index" => element_index}) do
    label_session = Labeling.get_label_session!(label_session_id)
    if label_session.blueprint, do: raise "Cannot label a blueprint session"  # Sanity

    label_job = Labeling.get_label_job!(label_session.job_id)
    element = Labeling.get_label_element!(label_session, element_index)
    labels = Labeling.list_element_labels(element)

    render(conn, "index.html", label_session: label_session, label_job: label_job, element: element, labels: labels)
  end

  def set_label(conn, %{"element_id" => element_id, "label_value" => label_value}) do
    element = Labeling.get_label_element!(element_id)
    session = Labeling.get_label_session!(element.session_id)

    _label_entry = Labeling.create_label_entry!(element, conn.assigns.current_user, label_value)

    redirect(conn, to: Routes.label_session_path(conn, :index, session, element.element_index))
  end
end
