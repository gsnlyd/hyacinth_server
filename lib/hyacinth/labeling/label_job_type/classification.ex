defmodule Hyacinth.Labeling.LabelJobType.Classification do
  alias Hyacinth.Labeling.LabelJobType
  alias Hyacinth.Warehouse.Object

  @behaviour LabelJobType

  @impl LabelJobType
  def name, do: :classification

  @impl LabelJobType
  def group_objects(objects) do
    Enum.map(objects, fn %Object{} = o ->
      [o]
    end)
  end
end
