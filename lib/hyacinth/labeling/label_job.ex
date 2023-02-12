defmodule Hyacinth.Labeling.LabelJob do
  use Hyacinth.Schema
  import Ecto.Changeset
  import Hyacinth.Validators

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Labeling.{LabelSession, LabelJobType}

  schema "label_jobs" do
    field :name, :string
    field :description, :string

    field :prompt, :string
    field :label_options, {:array, :string}

    field :type, Ecto.Enum, values: [:classification, :comparison_exhaustive, :comparison_mergesort], default: :classification
    field :options, :map, default: %{}

    field :label_options_string, :string, virtual: true

    belongs_to :dataset, Dataset
    belongs_to :created_by_user, User

    has_one :blueprint, LabelSession, foreign_key: :job_id, where: [blueprint: true]

    timestamps()
  end

  @doc false
  def changeset(label_job, attrs) do
    label_job
    |> cast(attrs, [:name, :description, :prompt, :label_options_string, :type, :options, :dataset_id])
    |> validate_required([:name, :label_options_string, :type, :options, :dataset_id])
    |> validate_length(:name, min: 1, max: 300)
    |> validate_length(:description, min: 1, max: 2000)
    |> validate_length(:label_options_string, min: 1, max: 1000)
    |> parse_comma_separated_string(:label_options_string, :label_options)
    |> validate_job_type_options()
  end

  defp validate_job_type_options(%Ecto.Changeset{} = changeset) do
    job_type = get_field(changeset, :type)
    options_params = get_field(changeset, :options)

    options_changeset = LabelJobType.options_changeset(job_type, options_params)
    if options_changeset.valid? do
      validated_options =
        options_changeset
        |> Ecto.Changeset.apply_action!(:insert)
        |> Map.from_struct()
        |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)

        put_change(changeset, :options, validated_options)
    else
      message = "not valid for type %{job_type}"
      keys = [job_type: job_type]
      add_error(changeset, :options, message, keys)
    end
  end
end
