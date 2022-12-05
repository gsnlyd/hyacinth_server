defmodule HyacinthWeb.DatasetLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.Warehouse

  defmodule DatasetFilterForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :type, Ecto.Enum, values: [:all, :root, :derived], default: :all
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

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      datasets: Warehouse.list_datasets_with_stats(),

      dataset_filter_changeset: DatasetFilterForm.changeset(%DatasetFilterForm{}, %{}),
    })
    {:ok, socket}
  end

  def filter_datasets(datasets, %Ecto.Changeset{} = changeset) when is_list(datasets) do
    %DatasetFilterForm{} = form = Ecto.Changeset.apply_changes(changeset)

    filter_func = fn %Warehouse.DatasetStats{dataset: dataset} ->
      contains_search?(dataset.name, form.search) and value_matches?(dataset.type, form.type)
    end

    {sort_func, sorter} =
      case form.sort_by do
        :name -> {&String.downcase(&1.dataset.name), form.order}
        :date_created -> {&(&1.dataset.inserted_at), {form.order, DateTime}}
      end

    datasets
    |> Enum.filter(filter_func)
    |> Enum.sort_by(sort_func, sorter)
  end

  def handle_event("dataset_filter_updated", %{"dataset_filter_form" => params}, socket) do
    changeset = DatasetFilterForm.changeset(%DatasetFilterForm{}, params)
    {:noreply, assign(socket, :dataset_filter_changeset, changeset)}
  end
end
