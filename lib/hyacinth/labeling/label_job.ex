defmodule Hyacinth.Labeling.LabelJob do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Labeling.LabelSession

  schema "label_jobs" do
    field :name, :string
    field :label_type, Ecto.Enum, values: [:classification]
    field :label_options, {:array, :string}

    field :label_options_string, :string, virtual: true

    belongs_to :dataset, Dataset
    belongs_to :created_by_user, User

    has_one :blueprint, LabelSession, foreign_key: :job_id, where: [blueprint: true]

    timestamps()
  end

  @doc false
  def changeset(label_job, attrs) do
    label_job
    |> cast(attrs, [:name, :label_type, :label_options_string, :dataset_id])
    |> validate_required([:name, :label_type, :label_options_string, :dataset_id])
    |> validate_length(:label_options_string, min: 1)
    |> parse_label_options_string()
  end

  def parse_label_options_string(%Ecto.Changeset{} = changeset) do

    if changeset.valid? do
      label_options_string = get_change(changeset, :label_options_string)

      split_options =
        label_options_string
        |> String.split(",", trim: true)
        |> Enum.map(&String.trim/1)

      changeset
      |> put_change(:label_options, split_options)
      |> delete_change(:label_options_string)
    else
      changeset
    end
  end
end
