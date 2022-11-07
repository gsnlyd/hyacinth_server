defmodule HyacinthWeb.DatasetLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.{Warehouse, Labeling}
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.LabelJob

  defmodule JobFilterForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :type, Ecto.Enum, values: [:all, :classification, :comparison_exhaustive], default: :all
      field :sort_by, Ecto.Enum, values: [:name, :date_created], default: :date_created
      field :order, Ecto.Enum, values: [:asc, :desc], default: :desc
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

      job_filter_changeset: JobFilterForm.changeset(%JobFilterForm{}, %{}),

      tab: :jobs,
    })
    {:ok, socket}
  end

  def filter_jobs(jobs, %Ecto.Changeset{} = changeset) when is_list(jobs) do
    %JobFilterForm{} = form = Ecto.Changeset.apply_changes(changeset)

    filter_func = fn %LabelJob{} = job ->
      contains_search?(job.name, form.search) and value_matches?(job.label_type, form.type)
    end

    {sort_func, sorter} =
      case form.sort_by do
        :name -> {&String.downcase(&1.name), form.order}
        :date_created -> {&(&1.inserted_at), {form.order, DateTime}}
      end

    jobs
    |> Enum.filter(filter_func)
    |> Enum.sort_by(sort_func, sorter)
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "jobs" -> :jobs
      "objects" -> :objects
    end
    {:noreply, assign(socket, :tab, tab)}
  end

  def handle_event("job_filter_updated", %{"job_filter_form" => params}, socket) do
    changeset = JobFilterForm.changeset(%JobFilterForm{}, params)
    {:noreply, assign(socket, :job_filter_changeset, changeset)}
  end
end
