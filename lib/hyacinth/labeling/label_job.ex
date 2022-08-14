defmodule Hyacinth.Labeling.LabelJob do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Accounts.User

  schema "label_jobs" do
    field :name, :string
    field :label_type, Ecto.Enum, values: [:classification]
    field :label_options, {:array, :string}

    belongs_to :dataset, Dataset
    belongs_to :created_by_user, User

    timestamps()
  end

  @doc false
  def changeset(label_job, attrs) do
    label_job
    |> cast(attrs, [:name, :label_type, :label_options, :dataset_id])
    |> validate_required([:name, :label_type, :label_options, :dataset_id])
  end
end
