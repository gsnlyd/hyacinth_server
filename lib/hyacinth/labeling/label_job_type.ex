defmodule Hyacinth.Labeling.LabelJobType do
  alias Hyacinth.Labeling.LabelJobType

  alias Hyacinth.Warehouse.Object

  @callback name() :: String.t

  @spec name(atom) :: String.t
  def name(job_type), do: module_for(job_type).name()

  @callback group_objects([%Object{}]) :: [[%Object{}]]

  @spec group_objects(atom, [%Object{}]) :: [[%Object{}]]
  def group_objects(job_type, objects), do: module_for(job_type).group_objects(objects)

  defp module_for(:classification), do: LabelJobType.Classification
  defp module_for(:comparison_exhaustive), do: LabelJobType.ComparisonExhaustive
end
