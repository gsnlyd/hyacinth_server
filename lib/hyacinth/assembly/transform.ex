defmodule Hyacinth.Assembly.Transform do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Assembly.{Pipeline, Driver}

  schema "transforms" do
    field :order_index, :integer
    field :driver, Ecto.Enum, values: [:sample, :slicer, :dicom_to_nifti], default: :sample
    field :options, :map

    belongs_to :pipeline, Pipeline

    timestamps()
  end

  @doc false
  def changeset(transform, attrs) do
    transform
    |> cast(attrs, [:order_index, :driver, :options])
    |> validate_required([:order_index, :driver, :options])
    |> validate_driver_options()
  end

  defp validate_driver_options(%Ecto.Changeset{} = changeset) do
    driver = get_field(changeset, :driver)
    options_params = get_field(changeset, :options)
    if options_params do
      options_changeset = Driver.options_changeset(driver, options_params)
      if not options_changeset.valid? do
        add_error(changeset, :options, "options are not valid for driver #{driver}")
      else
        valid_options_params =
          options_changeset
          |> Ecto.Changeset.apply_action!(:insert)
          |> Map.from_struct()
        put_change(changeset, :options, valid_options_params)
      end
    else
      changeset
    end
  end
end
