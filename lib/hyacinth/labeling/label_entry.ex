defmodule Hyacinth.Labeling.LabelEntry do
  use Hyacinth.Schema

  alias Hyacinth.Labeling.LabelElement

  schema "label_entries" do
    embeds_one :value, Value, primary_key: false do
      field :option, :string
    end

    embeds_one :metadata, Metadata, primary_key: false do
      field :started_at, :utc_datetime_usec
      field :completed_at, :utc_datetime_usec
    end

    belongs_to :element, LabelElement

    timestamps()
  end
end
