defmodule HyacinthWeb.PipelineLive.Show do
  use HyacinthWeb, :live_view

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
    def changeset(filter_options, attrs) do
      filter_options
      |> cast(attrs, [:dataset_id])
      |> validate_required([:dataset_id])
    end
  end

  def mount(params, _session, socket) do
    pipeline = Assembly.get_pipeline_preloaded!(params["pipeline_id"])

    if connected?(socket), do: Assembly.subscribe_pipeline_run_updates(pipeline)

    socket = assign(socket, %{
      pipeline: pipeline,
      transforms: Assembly.list_transforms(pipeline),

      datasets: Warehouse.list_datasets(),

      run_pipeline_changeset: RunPipelineForm.changeset(%RunPipelineForm{}, %{}),

      tab: :runs,
    })

    {:ok, socket}
  end

  def handle_event("run_pipeline_submit", %{"run_pipeline_form" => params}, socket) do
    changeset = RunPipelineForm.changeset(%RunPipelineForm{}, params)
    dataset_id = Ecto.Changeset.apply_changes(changeset).dataset_id

    case dataset_id do
      dataset_id when is_integer(dataset_id) ->
        %Dataset{} = dataset = Warehouse.get_dataset!(dataset_id)
        %PipelineRun{} = pipeline_run = Assembly.create_pipeline_run!(socket.assigns.pipeline, dataset, socket.assigns.current_user)
        :ok = Runner.run_pipeline(pipeline_run)

      nil ->
        nil
    end
    {:noreply, assign(socket, :run_pipeline_changeset, changeset)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "runs" -> :runs
      "steps" -> :steps
    end
    {:noreply, assign(socket, :tab, tab)}
  end

  def handle_info({:pipeline_run_updated, {_id, _status}}, socket) do
    pipeline = Assembly.get_pipeline_preloaded!(socket.assigns.pipeline.id)
    {:noreply, assign(socket, :pipeline, pipeline)}
  end
end
