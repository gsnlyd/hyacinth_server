defmodule Hyacinth.Labeling.LabelEntry do
  use Hyacinth.Schema

  alias Hyacinth.Labeling.LabelElement

  schema "label_entries" do
    field :label_value, :string

    belongs_to :element, LabelElement

    timestamps()
  end
end
