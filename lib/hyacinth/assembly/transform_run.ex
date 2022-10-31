defmodule Hyacinth.Assembly.TransformRun do
  use Hyacinth.Schema

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
end
