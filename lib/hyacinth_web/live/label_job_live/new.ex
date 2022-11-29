defmodule HyacinthWeb.LabelJobLive.New do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, Labeling}
  alias Hyacinth.Labeling.{LabelJob, LabelJobType}

  def mount(params, _session, socket) do
    dataset = if params["dataset"], do: Warehouse.get_dataset!(params["dataset"]), else: nil

    socket = assign(socket, %{
      dataset: dataset,
      datasets: Warehouse.list_datasets(),
      changeset: LabelJob.changeset(%LabelJob{dataset_id: if(dataset, do: dataset.id, else: nil)}, %{}),

      options_params: %{},

      modal: nil,
    })
    {:ok, socket}
  end

  def handle_event("form_change", %{"label_job" => params}, socket) do
    params = Map.put(params, "options", socket.assigns.options_params)
    changeset =
      %LabelJob{}
      |> LabelJob.changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("form_submit", %{"label_job" => params}, socket) do
    params = Map.put(params, "options", socket.assigns.options_params)
    case Labeling.create_label_job(params, socket.assigns.current_user) do
      {:ok, %LabelJob{} = job} ->
        socket = push_redirect(socket, to: Routes.live_path(socket, HyacinthWeb.LabelJobLive.Show, job))
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :changeset, changeset)
        {:noreply, socket}
    end
  end

  def handle_event("options_form_change", %{"options" => params}, socket) do
    options_changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.get_field(:type)
      |> LabelJobType.options_changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :modal, {:job_type_options, options_changeset})}
  end

  def handle_event("options_form_submit", %{"options" => params}, socket) do
    options_changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.get_field(:type)
      |> LabelJobType.options_changeset(params)

    case Ecto.Changeset.apply_action(options_changeset, :insert) do
      {:ok, schema} ->
        validated_options = Map.from_struct(schema)

        new_job_params = Map.put(socket.assigns.changeset.params, "options", validated_options)
        changeset =
          %LabelJob{}
          |> LabelJob.changeset(new_job_params)
          |> Map.put(:action, :insert)

        socket = assign(socket, %{
          changeset: changeset,
          options_params: validated_options,
          modal: nil,
        })

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = options_changeset} ->
        {:noreply, assign(socket, :modal, {:job_type_options, options_changeset})}
    end
  end

  def handle_event("edit_job_type_options", _params, socket) do
    options_changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.get_field(:type)
      |> LabelJobType.options_changeset(socket.assigns.options_params)
    {:noreply, assign(socket, :modal, {:job_type_options, options_changeset})}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :modal, nil)}
  end
end
