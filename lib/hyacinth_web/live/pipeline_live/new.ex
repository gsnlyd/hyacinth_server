defmodule HyacinthWeb.PipelineLive.New do
  use HyacinthWeb, :live_view

  alias Hyacinth.Assembly.Pipeline

  defmodule TransformArgs do
    # TODO: this schema is for testing, remove later
    use Hyacinth.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field :object_count, :integer, default: 100
      field :random_seed, :string, default: "100"
    end

    @doc false
    def changeset(transform_args, attrs) do
      transform_args
      |> cast(attrs, [:name, :object_count, :random_seed])
      |> validate_required([:name, :object_count, :random_seed])
      |> validate_length(:name, min: 1, max: 10)
      |> validate_number(:object_count, greater_than: 0, less_than: 20)
      |> validate_length(:random_seed, min: 1, max: 10)
    end
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      pipeline_changeset: Ecto.Changeset.change(%Pipeline{}),
      transforms: [],
    })

    {:ok, socket}
  end

  def handle_event("validate_pipeline", %{"pipeline" => pipeline_params}, socket) do
    IO.inspect pipeline_params
    changeset =
      %Pipeline{}
      |> Pipeline.changeset(pipeline_params)
      |> Map.put(:action, :insert)
    IO.inspect changeset

    socket = assign(socket, :pipeline_changeset, changeset)
    {:noreply, socket}
  end

  def handle_event("add_transform", _value, socket) do
    transforms = socket.assigns.transforms ++ [TransformArgs.changeset(%TransformArgs{}, %{})]
    socket = assign(socket, :transforms, transforms)
    {:noreply, socket}
  end

  def handle_event("remove_transform", %{"transform-index" => transform_index}, socket) do
    transform_index = String.to_integer(transform_index)
    transforms = List.delete_at(socket.assigns.transforms, transform_index)
    socket = assign(socket, :transforms, transforms)
    {:noreply, socket}
  end
end
