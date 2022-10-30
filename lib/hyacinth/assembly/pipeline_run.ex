defmodule Hyacinth.Assembly.PipelineRun do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Accounts.User
  alias Hyacinth.Assembly.Pipeline

  schema "pipeline_runs" do
    field :status, Ecto.Enum, values: [:running, :complete]
    field :completed_at, :utc_datetime_usec

    belongs_to :ran_by, User
    belongs_to :pipeline, Pipeline

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
