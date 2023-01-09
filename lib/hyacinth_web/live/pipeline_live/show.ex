defmodule HyacinthWeb.PipelineLive.Show do
  use HyacinthWeb, :live_view

  import HyacinthWeb.LiveUtils

  alias Hyacinth.{Assembly, Warehouse}
  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.{PipelineRun, Runner}

  defmodule RunPipelineForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :dataset_id, :integer
    end

    @doc false
    def changeset(data, attrs) do
      data
      |> cast(attrs, [:dataset_id])
      |> validate_required([:dataset_id])
    end
  end

  defmodule RunFilterForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :status, Ecto.Enum, values: [:all, :running, :complete, :failed], default: :all
      field :sort_by, Ecto.Enum, values: [:dataset_name, :date_created], default: :date_created
      field :order, Ecto.Enum, values: [:asc, :desc], default: :desc
    end

    @doc false
    def changeset(filter_options, attrs) do
      filter_options
      |> cast(attrs, [:search, :status, :sort_by, :order])
      |> validate_required([:search, :status, :sort_by, :order])
    end
  end


  def mount(params, _session, socket) do
    pipeline = Assembly.get_pipeline_preloaded!(params["pipeline_id"])

    if connected?(socket), do: Assembly.subscribe_pipeline_run_updates(pipeline)

    socket = assign(socket, %{
      pipeline: pipeline,
      transforms: Assembly.list_transforms(pipeline),
      datasets: Warehouse.list_datasets(),

      run_filter_changeset: RunFilterForm.changeset(%RunFilterForm{}, %{}),

      tab: :runs,

      modal: nil,
    })

    {:ok, socket}
  end

  defp filter_runs(runs, %Ecto.Changeset{} = changeset) when is_list(runs) do
    %RunFilterForm{} = form = Ecto.Changeset.apply_changes(changeset)

    filter_func = fn %PipelineRun{} = run ->
      %Dataset{} = input = hd(run.transform_runs).input
      contains_search?([input.name, run.ran_by.email], form.search) and value_matches?(run.status, form.status)
    end

    {sort_func, sorter} =
      case form.sort_by do
        :dataset_name -> {&String.downcase(hd(&1.transform_runs).input.name), form.order}
        :date_created -> {&(&1.inserted_at), {form.order, DateTime}}
      end

    runs
    |> Enum.filter(filter_func)
    |> Enum.sort_by(sort_func, sorter)
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "runs" -> :runs
      "steps" -> :steps
    end
    {:noreply, assign(socket, :tab, tab)}
  end

  def handle_event("run_filter_updated", %{"run_filter_form" => params}, socket) do
    changeset = RunFilterForm.changeset(%RunFilterForm{}, params)
    {:noreply, assign(socket, :run_filter_changeset, changeset)}
  end

  def handle_event("run_pipeline_form_change", %{"run_pipeline_form" => params}, socket) do
    changeset =
      %RunPipelineForm{}
      |> RunPipelineForm.changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :modal, {:run_pipeline, changeset})}
  end

  def handle_event("run_pipeline_form_submit", %{"run_pipeline_form" => params}, socket) do
    changeset = RunPipelineForm.changeset(%RunPipelineForm{}, params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %RunPipelineForm{} = schema} ->
        %Dataset{} = dataset = Warehouse.get_dataset!(schema.dataset_id)
        %PipelineRun{} = pipeline_run = Assembly.create_pipeline_run!(socket.assigns.pipeline, dataset, socket.assigns.current_user)
        :ok = Runner.run_pipeline(pipeline_run)

        {:noreply, push_redirect(socket, to: Routes.live_path(socket, HyacinthWeb.PipelineRunLive.Show, pipeline_run))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :modal, {:run_pipeline, changeset})}
    end
  end

  def handle_event("open_modal_run_pipeline", _params, socket) do
    changeset = RunPipelineForm.changeset(%RunPipelineForm{}, %{})
    {:noreply, assign(socket, :modal, {:run_pipeline, changeset})}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :modal, nil)}
  end

  def handle_info({:pipeline_run_updated, {_id, _status}}, socket) do
    pipeline = Assembly.get_pipeline_preloaded!(socket.assigns.pipeline.id)
    {:noreply, assign(socket, :pipeline, pipeline)}
  end
end
