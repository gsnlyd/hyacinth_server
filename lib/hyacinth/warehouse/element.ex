defmodule Hyacinth.Warehouse.Element do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.{Dataset, Element}

  schema "elements" do
    field :path, :string
    field :element_type, :string

    belongs_to :dataset, Dataset
    belongs_to :parent_element, Element

    timestamps()
  end

  @doc false
  def changeset(element, attrs) do
    element
    |> cast(attrs, [:path, :element_type, :dataset_id, :parent_element_id])
    |> validate_required([:path, :element_type, :dataset_id])
  end
end
