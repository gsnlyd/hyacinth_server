defmodule Hyacinth.Labeling.LabelJobType.ComparisonExhaustive do
  alias Hyacinth.Labeling.LabelJobType

  defmodule ComparisonExhaustiveOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :randomize, :boolean, default: true
      field :random_seed, :integer, default: 123
    end

    @doc false
    def changeset(schema, params) do
      schema
      |> cast(params, [:randomize, :random_seed])
      |> validate_required([:randomize, :random_seed])
      |> validate_number(:random_seed, greater_than: 0)
    end
  end

  @behaviour LabelJobType

  @impl LabelJobType
  def name, do: "Comparison (Exhaustive)"

  @impl LabelJobType
  def options_changeset(params), do: ComparisonExhaustiveOptions.changeset(%ComparisonExhaustiveOptions{}, params)

  @impl LabelJobType
  def render_form(assigns) do
    import Phoenix.LiveView.Helpers
    import Phoenix.HTML.Form
    import HyacinthWeb.ErrorHelpers

    ~H"""
    <div class="form-content">
      <p>
        <%= label @form, :randomize %>
        <%= checkbox @form, :randomize %>
        <%= error_tag @form, :randomize %>
      </p>

      <p>
        <%= label @form, :random_seed %>
        <%= number_input @form, :random_seed %>
        <%= error_tag @form, :random_seed %>
      </p>
    </div>
    """
  end

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
