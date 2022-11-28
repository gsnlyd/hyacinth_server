defmodule Hyacinth.Labeling.LabelJobType do
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.LabelJob

  @callback name() :: atom()

  def name(%LabelJob{} = job), do: module_for(job).name()

  @callback group_objects([%Object{}]) :: [[%Object{}]]

  def group_objects(%LabelJob{} = job, objects), do: module_for(job).group_objects(objects)

  defp module_for(%LabelJob{type: :classification}), do: Hyacinth.Labeling.LabelJobType.Classification
  defp module_for(%LabelJob{type: :comparison_exhaustive}), do: Hyacinth.Labeling.LabelJobType.ComparisonExhaustive
end
