defmodule HyacinthWeb.LabelJobLive.New do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, Labeling}
  alias Hyacinth.Labeling.{LabelJob}

  def mount(params, _session, socket) do
    dataset = if params["dataset"], do: Warehouse.get_dataset!(params["dataset"]), else: nil

    socket = assign(socket, %{
      dataset: dataset,
      datasets: Warehouse.list_datasets(),
      changeset: LabelJob.changeset(%LabelJob{dataset_id: if(dataset, do: dataset.id, else: nil)}, %{}),
    })
    {:ok, socket}
  end

  def handle_event("form_change", %{"label_job" => params}, socket) do
    changeset =
      %LabelJob{}
      |> LabelJob.changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("form_submit", %{"label_job" => params}, socket) do
    case Labeling.create_label_job(params, socket.assigns.current_user) do
      {:ok, %LabelJob{} = job} ->
        socket = push_redirect(socket, to: Routes.live_path(socket, HyacinthWeb.LabelJobLive.Show, job))
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :changeset, changeset)
        {:noreply, socket}
    end
  end
end
