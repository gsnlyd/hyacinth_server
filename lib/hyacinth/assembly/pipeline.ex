defmodule Hyacinth.Assembly.Pipeline do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Assembly

  alias Hyacinth.Accounts.User
  alias Hyacinth.Assembly.{Transform, PipelineRun}

  schema "pipelines" do
    field :name, :string

    belongs_to :creator, User

    has_many :transforms, Transform
    has_many :runs, PipelineRun

    timestamps()
  end

  @doc false
  def changeset(pipeline, attrs) do
    pipeline
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:transforms, with: &Transform.changeset/2)
    |> validate_length(:name, min: 1, max: 30)
    |> validate_transforms_not_empty()
    |> validate_transform_order()
    |> validate_transform_inputs_match_outputs()
  end

  defp validate_transforms_not_empty(%Ecto.Changeset{} = changeset) do
    transforms = get_field(changeset, :transforms)
    if length(transforms) == 0 do
      add_error(changeset, :transforms, "can't be empty")
    else
      changeset
    end
  end

  defp validate_transform_order(%Ecto.Changeset{} = changeset) do
    transforms = get_field(changeset, :transforms)
    indices = Enum.map(transforms, fn %Transform{} = t -> t.order_index end)
    if length(transforms) > 0 and indices != Enum.to_list(0..(length(transforms) - 1)) do
      add_error(changeset, :transforms, "can't be out of order")
    else
      changeset
    end
  end

  defp validate_transform_inputs_match_outputs(%Ecto.Changeset{} = changeset) do
    changeset
    |> get_field(:transforms)
    |> Assembly.check_transform_formats()
    |> Enum.with_index()
    |> Enum.filter(&(elem(&1, 0) != nil))
    |> Enum.map(fn {{expected, found}, i} ->
      "Step #{i + 1} expected format #{expected}, got #{found}"
    end)
    |> Enum.reduce(changeset, fn error, %Ecto.Changeset{} = changeset ->
      add_error(changeset, :transforms, error)
    end)
  end
end
