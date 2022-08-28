defmodule Hyacinth.Assembly.Transform do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transforms" do
    field :arguments, :map
    field :driver, :string
    field :order_index, :integer
    field :pipeline_id, :id
    field :input_id, :id
    field :output_id, :id

    timestamps()
  end

  @doc false
  def changeset(transform, attrs) do
    transform
    |> cast(attrs, [:order_index, :driver, :arguments])
    |> validate_required([:order_index, :driver, :arguments])
  end
end
