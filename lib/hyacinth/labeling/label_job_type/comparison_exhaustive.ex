defmodule Hyacinth.Labeling.LabelJobType.ComparisonExhaustive do
  alias Hyacinth.Labeling.LabelJobType

  @behaviour LabelJobType

  @impl LabelJobType
  def name, do: "Comparison (Exhaustive)"

  @impl LabelJobType
  def group_objects(objects) do
    combinations(objects)
  end

  # TODO: move this function somewhere else
  defp combinations(items) when is_list(items) do
    Enum.map(Enum.with_index(items), fn {item1, i} ->
      slice_start = i + 1
      Enum.map(Enum.slice(items, slice_start..-1//1), fn item2 ->
        [item1, item2]
      end)
    end)
    |> Enum.concat()
  end
end
