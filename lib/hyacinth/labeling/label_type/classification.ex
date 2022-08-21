defmodule Hyacinth.Labeling.LabelType.Classification do
  alias Hyacinth.Labeling.LabelType
  alias Hyacinth.Warehouse.Object

  @behaviour LabelType

  @impl LabelType
  def name, do: :classification

  @impl LabelType
  def group_objects(objects) do
    Enum.map(objects, fn %Object{} = o ->
      [o]
    end)
  end
end
