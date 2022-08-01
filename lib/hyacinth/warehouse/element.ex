defmodule Hyacinth.Warehouse.Element do
  use Ecto.Schema
  import Ecto.Changeset

  schema "elements" do
    field :element_type, :string
    field :path, :string
    field :dataset_id, :id
    field :parent_element_id, :id
    field :created_by_user_id, :id

    timestamps()
  end

  @doc false
  def changeset(element, attrs) do
    element
    |> cast(attrs, [:path, :element_type])
    |> validate_required([:path, :element_type])
  end
end
