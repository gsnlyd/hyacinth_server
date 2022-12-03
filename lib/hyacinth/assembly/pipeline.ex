defmodule Hyacinth.Assembly.Pipeline do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Assembly

  alias Hyacinth.Accounts.User
  alias Hyacinth.Assembly.{Transform, PipelineRun}

  schema "pipelines" do
    field :name, :string
    field :description, :string

    belongs_to :creator, User

    has_many :transforms, Transform
    has_many :runs, PipelineRun

    timestamps()
  end

  @doc false
  def changeset(pipeline, attrs) do
    pipeline
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> cast_assoc(:transforms, with: &Transform.changeset/2, required: true, required_message: "can't be empty")
    |> validate_length(:name, min: 1, max: 30)
    |> validate_transform_order()
    |> validate_transform_inputs_match_outputs()
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
    |> Enum.reduce(changeset, fn {{expected, found}, i}, %Ecto.Changeset{} = changeset ->
      update_change(changeset, :transforms, fn transforms ->
        List.update_at(transforms, i, fn transform_changeset ->
          message = "requires format %{expected}, but previous step outputs %{found}"
          keys = [expected: expected, found: found]
          add_error(transform_changeset, :driver, message, keys)
        end)
      end)
    end)
  end
end
