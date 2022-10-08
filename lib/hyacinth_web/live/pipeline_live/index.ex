defmodule HyacinthWeb.PipelineLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Assembly}

  alias Hyacinth.Assembly.Pipeline

  defmodule PipelineFilterOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :sort_by, Ecto.Enum, values: [:name, :date_created, :transforms], default: :date_created
      field :order, Ecto.Enum, values: [:ascending, :descending], default: :descending
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

      filter_changeset: PipelineFilterOptions.changeset(%PipelineFilterOptions{}, %{}),
    })
    {:ok, socket}
  end

  @spec filter_pipelines([%Pipeline{}], %Ecto.Changeset{}) :: [%Pipeline{}]
  def filter_pipelines(pipelines, %Ecto.Changeset{} = filter_changeset) when is_list(pipelines) do
    %PipelineFilterOptions{} = options = Ecto.Changeset.apply_changes(filter_changeset)

    pipelines_filtered =
      Enum.filter(pipelines, fn %Pipeline{} = pipeline ->
        options.search == "" or String.contains?(String.downcase(pipeline.name), String.downcase(options.search))
      end)

    pipelines_sorted =
      case options.sort_by do
        :name -> Enum.sort_by(pipelines_filtered, &String.downcase(&1.name))
        :date_created -> Enum.sort_by(pipelines_filtered, &(&1.inserted_at), DateTime)
        :transforms -> Enum.sort_by(pipelines_filtered, &length(&1.transforms))
      end

    case options.order do
      :ascending -> pipelines_sorted
      :descending -> Enum.reverse(pipelines_sorted)
    end
  end

  def handle_event("filter_updated", %{"pipeline_filter_options" => params}, socket) do
    changeset = PipelineFilterOptions.changeset(%PipelineFilterOptions{}, params)
    {:noreply, assign(socket, :filter_changeset, changeset)}
  end
end
