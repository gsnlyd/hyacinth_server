defmodule HyacinthWeb.DatasetLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, Labeling}
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.LabelJob

  defmodule JobFilterOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :type, Ecto.Enum, values: [:all, :classification, :comparison_exhaustive], default: :all
      field :sort_by, Ecto.Enum, values: [:name, :date_created], default: :date_created
      field :order, Ecto.Enum, values: [:ascending, :descending], default: :descending
    end

    @doc false
    def changeset(filter_options, attrs) do
      filter_options
      |> cast(attrs, [:search, :type, :sort_by, :order])
      |> validate_required([:search, :type, :sort_by, :order])
    end
  end


  def mount(params, _session, socket) do
    dataset = Warehouse.get_dataset!(params["dataset_id"])
    socket = assign(socket, %{
      dataset: dataset,
      jobs: Labeling.list_label_jobs(dataset),
      objects: Warehouse.list_objects(dataset),

      job_filter_changeset: JobFilterOptions.changeset(%JobFilterOptions{}, %{}),

      tab: :jobs,
    })
    {:ok, socket}
  end

  @spec filter_jobs([%LabelJob{}], %Ecto.Changeset{}) :: [%LabelJob{}]
  def filter_jobs(jobs, %Ecto.Changeset{} = filter_changeset) when is_list(jobs) do
    %JobFilterOptions{} = options = Ecto.Changeset.apply_changes(filter_changeset)

    jobs_filtered =
      Enum.filter(jobs, fn %LabelJob{} = job ->
        (options.search == "" or String.contains?(String.downcase(job.name), String.downcase(options.search))) and
        (options.type == :all or options.type == job.label_type)
      end)

    jobs_sorted =
      case options.sort_by do
        :name -> Enum.sort_by(jobs_filtered, &(String.downcase(&1.name)))
        :date_created -> Enum.sort_by(jobs_filtered, &(&1.inserted_at), DateTime)
      end

    case options.order do
      :ascending -> jobs_sorted
      :descending -> Enum.reverse(jobs_sorted)
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "jobs" -> :jobs
      "objects" -> :objects
    end
    {:noreply, assign(socket, :tab, tab)}
  end

  def handle_event("job_filter_updated", %{"job_filter_options" => params}, socket) do
    changeset = JobFilterOptions.changeset(%JobFilterOptions{}, params)
    {:noreply, assign(socket, :job_filter_changeset, changeset)}
  end
end
