defmodule HyacinthWeb.DatasetLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.Dataset

  defmodule FilterOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :type, Ecto.Enum, values: [:all, :root, :derived], default: :all
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

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      datasets: Warehouse.list_datasets_with_counts(),

      filter_changeset: FilterOptions.changeset(%FilterOptions{}, %{}),
    })
    {:ok, socket}
  end

  def filter_datasets(datasets, filter_changeset) do
    %FilterOptions{} = options = Ecto.Changeset.apply_changes(filter_changeset)

    datasets_filtered =
      Enum.filter(datasets, fn {%Dataset{} = dataset, _, _} ->
        (options.search == "" or String.contains?(String.downcase(dataset.name), String.downcase(options.search))) and
        (options.type == :all or options.type == dataset.type)
      end)

    datasets_sorted =
      case options.sort_by do
        :name -> Enum.sort_by(datasets_filtered, &(String.downcase(elem(&1, 0).name)))
        :date_created -> Enum.sort_by(datasets_filtered, &(elem(&1, 0).inserted_at), DateTime)
      end

    case options.order do
      :ascending -> datasets_sorted
      :descending -> Enum.reverse(datasets_sorted)
    end
  end

  def handle_event("filter_updated", %{"filter_options" => params}, socket) do
    changeset = FilterOptions.changeset(%FilterOptions{}, params)
    socket = assign(socket, :filter_changeset, changeset)
    {:noreply, socket}
  end
end
