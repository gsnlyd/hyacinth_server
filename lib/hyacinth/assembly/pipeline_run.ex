defmodule Hyacinth.Assembly.PipelineRun do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pipeline_runs" do
    field :completed_at, :utc_datetime_usec
    field :status, Ecto.Enum, values: [:running, :complete]
    field :ran_by_id, :id
    field :pipeline_id, :id

    timestamps()
  end

  @doc false
  def changeset(pipeline_run, attrs) do
    pipeline_run
    |> cast(attrs, [:status, :completed_at])
    |> validate_required([:status, :completed_at])
  end
end
