defmodule Hyacinth.Assembly.TransformRun do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.{Transform, PipelineRun}

  schema "transform_runs" do
    field :order_index, :integer
    field :status, Ecto.Enum, values: [:waiting, :running, :complete]

    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    belongs_to :input, Dataset
    belongs_to :output, Dataset

    belongs_to :pipeline_run, PipelineRun
    belongs_to :transform, Transform

    timestamps()
  end

  @doc false
  def changeset(transform_run, attrs) do
    transform_run
    |> cast(attrs, [:order_index, :status, :started_at, :completed_at, :input_id, :output_id, :pipeline_run_id, :transform_id])
    |> validate_required([:order_index, :status, :pipeline_run_id, :transform_id])
    |> assoc_constraint(:input)
    |> assoc_constraint(:output)
    |> assoc_constraint(:pipeline_run)
    |> assoc_constraint(:transform)
  end
end
