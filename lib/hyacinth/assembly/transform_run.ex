defmodule Hyacinth.Assembly.TransformRun do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transform_runs" do
    field :completed_at, :utc_datetime_usec
    field :order_index, :integer
    field :started_at, :utc_datetime_usec
    field :status, Ecto.Enum, values: [:waiting, :running, :complete]
    field :input_id, :id
    field :output_id, :id
    field :pipeline_run_id, :id
    field :transform_id, :id

    timestamps()
  end

  @doc false
  def changeset(transform_run, attrs) do
    transform_run
    |> cast(attrs, [:order_index, :status, :started_at, :completed_at])
    |> validate_required([:order_index, :status, :started_at, :completed_at])
  end
end
