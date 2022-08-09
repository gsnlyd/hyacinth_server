defmodule Hyacinth.Warehouse.Element do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.{Dataset, Element}
  alias Hyacinth.Accounts.User

  schema "elements" do
    field :path, :string
    field :element_type, :string

    belongs_to :dataset, Dataset
    belongs_to :parent_element, Element
    belongs_to :created_by_user, User

    timestamps()
  end

  @doc false
  def changeset(element, attrs) do
    element
    |> cast(attrs, [:path, :element_type])
    |> validate_required([:path, :element_type])
  end
end
