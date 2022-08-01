defmodule Hyacinth.Labeling.LabelJob do
  use Ecto.Schema
  import Ecto.Changeset

  schema "label_jobs" do
    field :label_type, Ecto.Enum, values: [:classification]
    field :name, :string
    field :dataset_id, :id
    field :created_by_user_id, :id

    timestamps()
  end

  @doc false
  def changeset(label_job, attrs) do
    label_job
    |> cast(attrs, [:name, :label_type])
    |> validate_required([:name, :label_type])
  end
end
