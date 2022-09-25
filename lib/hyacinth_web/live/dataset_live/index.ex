defmodule HyacinthWeb.DatasetLive.Index do
  use HyacinthWeb, :live_view

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.Dataset

  defmodule SortOptions do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :sort_by, Ecto.Enum, values: [:name, :date_created], default: :date_created
      field :order, Ecto.Enum, values: [:ascending, :descending], default: :descending
    end

    @doc false
    def changeset(sort_options, attrs) do
      sort_options
      |> cast(attrs, [:sort_by, :order])
      |> validate_required([:sort_by, :order])
    end
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      datasets: Warehouse.list_datasets_with_counts(),

      sort_changeset: SortOptions.changeset(%SortOptions{}, %{}),
      sort_by: :date_created,
      order: :descending,
    })
    {:ok, socket}
  end

  def sort_datasets(datasets, sort_by, order) do
    sorter =
      case order do
        :ascending -> :asc
        :descending -> :desc
      end

    Enum.sort_by(datasets, fn {%Dataset{} = dataset, _, _} ->
      case sort_by do
        :name -> String.downcase(dataset.name)
        :date_created -> dataset.inserted_at
      end
    end, sorter)
  end

  def handle_event("sort_updated", %{"sort_options" => params}, socket) do
    changeset = SortOptions.changeset(%SortOptions{}, params)
    socket = assign(socket, %{
      sort_changeset: changeset,
      sort_by: Ecto.Changeset.get_field(changeset, :sort_by),
      order: Ecto.Changeset.get_field(changeset, :order),
    })
    {:noreply, socket}
  end
end
