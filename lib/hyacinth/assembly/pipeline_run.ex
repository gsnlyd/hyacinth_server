defmodule Hyacinth.Assembly.PipelineRun do
  use Hyacinth.Schema

  alias Hyacinth.Accounts.User
  alias Hyacinth.Assembly.{Pipeline, TransformRun}

  schema "pipeline_runs" do
    field :status, Ecto.Enum, values: [:running, :complete, :failed]
    field :completed_at, :utc_datetime_usec

    belongs_to :ran_by, User
    belongs_to :pipeline, Pipeline

    has_many :transform_runs, TransformRun, preload_order: [asc: :order_index]

    timestamps()
  end
end
