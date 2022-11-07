defmodule HyacinthWeb.PipelineLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Assembly}

  alias Hyacinth.Assembly.Pipeline

  defmodule PipelineFilterForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :sort_by, Ecto.Enum, values: [:name, :date_created, :runs], default: :date_created
      field :order, Ecto.Enum, values: [:asc, :desc], default: :desc
    end

    @doc false
    def changeset(filter_options, attrs) do
      filter_options
      |> cast(attrs, [:search, :sort_by, :order])
      |> validate_required([:search, :sort_by, :order])
    end
  end


  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      pipelines: Assembly.list_pipelines_preloaded(),

      pipeline_filter_changeset: PipelineFilterForm.changeset(%PipelineFilterForm{}, %{}),
    })
    {:ok, socket}
  end

  def filter_pipelines(pipelines, %Ecto.Changeset{} = changeset) when is_list(pipelines) do
    %PipelineFilterForm{} = form = Ecto.Changeset.apply_changes(changeset)

    filter_func = fn %Pipeline{} = pipeline ->
      contains_search?(pipeline.name, form.search)
    end

    {sort_func, sorter} =
      case form.sort_by do
        :name -> {&String.downcase(&1.name), form.order}
        :date_created -> {&(&1.inserted_at), {form.order, DateTime}}
        :runs -> {&length(&1.runs), form.order}
      end

    pipelines
    |> Enum.filter(filter_func)
    |> Enum.sort_by(sort_func, sorter)
  end

  def handle_event("pipeline_filter_updated", %{"pipeline_filter_form" => params}, socket) do
    changeset = PipelineFilterForm.changeset(%PipelineFilterForm{}, params)
    {:noreply, assign(socket, :pipeline_filter_changeset, changeset)}
  end
end
