defmodule Hyacinth.Assembly.Transform do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.Pipeline

  schema "transforms" do
    field :order_index, :integer
    field :driver, Ecto.Enum, values: [:slicer], default: :slicer
    field :arguments, :map

    belongs_to :pipeline, Pipeline
    belongs_to :input, Dataset
    belongs_to :output, Dataset

    timestamps()
  end

  @doc false
  def changeset(transform, attrs) do
    transform
    |> cast(attrs, [:order_index, :driver, :arguments])
    |> validate_required([:order_index, :driver, :arguments])
  end
end
