defmodule Hyacinth.Labeling.LabelJobType.ComparisonExhaustive do
  alias Hyacinth.Labeling.LabelJobType

  defmodule ComparisonExhaustiveOptions do
    use Ecto.Schema
    import Ecto.Changeset
    import Hyacinth.Validators

    @primary_key false
    embedded_schema do
      field :randomize, :boolean, default: true
      field :random_seed, :integer, default: 123
      field :comparison_label_options_raw_input, :string, default: "First Image, Second Image"
      field :comparison_label_options, {:array, :string}
    end

    @doc false
    def changeset(schema, params) do
      schema
      |> cast(params, [:randomize, :random_seed, :comparison_label_options_raw_input])
      |> validate_required([:randomize, :random_seed, :comparison_label_options_raw_input])
      |> validate_number(:random_seed, greater_than: 0)
      |> parse_comma_separated_string(:comparison_label_options_raw_input, :comparison_label_options, keep_string: true)
    end

    @doc false
    def parse(params) do
      %ComparisonExhaustiveOptions{}
      |> changeset(params)
      |> apply_changes()
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

      <p>
        <%= label @form, :comparison_label_options_raw_input, "Comparison label options" %>
        <%= text_input @form, :comparison_label_options_raw_input, placeholder: "First, Second" %>
        <%= error_tag @form, :comparison_label_options_raw_input, name: "Comparison label options" %>
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

  @impl LabelJobType
  def list_object_label_options(options) do
    options = ComparisonExhaustiveOptions.parse(options)
    options.comparison_label_options
  end
end
