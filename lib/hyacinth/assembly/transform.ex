defmodule Hyacinth.Assembly.Transform do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  schema "transforms" do
    field :order_index, :integer
    field :driver, Ecto.Enum, values: [:sample, :slicer], default: :sample
    field :arguments, :map

    belongs_to :pipeline, Pipeline
    belongs_to :input, Dataset
    belongs_to :output, Dataset

    timestamps()
  end

  @doc false
  def changeset(transform, attrs) do
    transform
    |> cast(attrs, [:order_index, :driver, :arguments, :input_id])
    |> validate_required([:order_index, :driver, :arguments])
    |> validate_input_dataset()
    |> validate_driver_options()
  end

  @doc false
  def update_input_changeset(%Transform{} = transform, attrs) do
    transform
    |> cast(attrs, [:input_id])
    |> validate_required([:input_id])
    |> foreign_key_constraint(:input_id)
  end

  @doc false
  def update_output_changeset(%Transform{} = transform, attrs) do
    transform
    |> cast(attrs, [:output_id])
    |> validate_required([:output_id])
    |> foreign_key_constraint(:output_id)
  end

  defp validate_input_dataset(%Ecto.Changeset{} = changeset) do
    if get_field(changeset, :order_index) == 0 do
      case get_field(changeset, :input_id) do
        nil ->
          add_error(changeset, :input_id, "can't be blank for the first transform")
        _ ->
          changeset
      end
    else
      case get_field(changeset, :input_id) do
        nil ->
          changeset
        _ ->
          add_error(changeset, :input_id, "can only be set for the first transform")
      end
    end
  end

  defp validate_driver_options(%Ecto.Changeset{} = changeset) do
    driver = get_field(changeset, :driver)
    options_params = get_field(changeset, :arguments)
    if options_params do
      options_changeset = Driver.options_changeset(driver, options_params)
      if not options_changeset.valid? do
        add_error(changeset, :arguments, "options are not valid for driver #{driver}")
      else
        valid_options_params =
          options_changeset
          |> Ecto.Changeset.apply_action!(:insert)
          |> Map.from_struct()
        put_change(changeset, :arguments, valid_options_params)
      end
    else
      changeset
    end
  end
end
