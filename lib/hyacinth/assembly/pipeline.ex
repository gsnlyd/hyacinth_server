defmodule Hyacinth.Assembly.Pipeline do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Accounts.User
  alias Hyacinth.Assembly.Transform

  schema "pipelines" do
    field :name, :string

    belongs_to :creator, User

    has_many :transforms, Transform

    timestamps()
  end

  @doc false
  def changeset(pipeline, attrs) do
    pipeline
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:transforms, with: &Transform.changeset/2)
    |> validate_length(:name, min: 1, max: 30)
    |> validate_transform_order()
  end

  defp validate_transform_order(%Ecto.Changeset{} = changeset) do
    transforms = get_field(changeset, :transforms)
    indices = Enum.map(transforms, fn %Transform{} = t -> t.order_index end)
    if indices != Enum.to_list(0..(length(transforms) - 1)) do
      add_error(changeset, :transforms, "can't be out of order")
    else
      changeset
    end
  end
end
