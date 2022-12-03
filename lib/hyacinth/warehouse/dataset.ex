defmodule Hyacinth.Warehouse.Dataset do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.DatasetObject
  alias Hyacinth.Labeling.LabelJob

  schema "datasets" do
    field :name, :string
    field :description, :string
    field :type, Ecto.Enum, values: [:root, :derived]

    has_many :dataset_objects, DatasetObject
    has_many :objects, through: [:dataset_objects, :object]

    has_many :jobs, LabelJob

    timestamps()
  end

  @doc false
  def create_changeset(dataset, attrs) do
    dataset
    |> cast(attrs, [:name, :description, :type])
    |> validate_required([:name, :type])
  end
end
