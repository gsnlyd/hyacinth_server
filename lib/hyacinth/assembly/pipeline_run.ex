defmodule Hyacinth.Assembly.PipelineRun do
  use Hyacinth.Schema
  import Ecto.Changeset

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

  @doc false
  def changeset(pipeline_run, attrs) do
    pipeline_run
    |> cast(attrs, [:status, :completed_at, :ran_by_id, :pipeline_id])
    |> validate_required([:status, :ran_by_id, :pipeline_id])
    |> assoc_constraint(:ran_by)
    |> assoc_constraint(:pipeline)
  end
end
