defmodule Hyacinth.Labeling.LabelJobType.ComparisonExhaustive do
  alias Hyacinth.Labeling.LabelJobType

  alias Hyacinth.Labeling.{LabelJob, LabelSession, LabelElement}
  alias Hyacinth.Warehouse.Object

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
  def group_objects(options, objects) do
    options = ComparisonExhaustiveOptions.parse(options)
    grouped = combinations(objects)
    if options.randomize do
      Hyacinth.RandomUtils.shuffle_seeded(options.random_seed, grouped)
    else
      grouped
    end
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

  @impl LabelJobType
  def session_results(options, %LabelJob{} = job, %LabelSession{} = label_session) do
    options = ComparisonExhaustiveOptions.parse(options)
    compute_results(options, job, label_session.elements)
  end

  @impl LabelJobType
  def job_results(options, job, label_sessions) do
    options = ComparisonExhaustiveOptions.parse(options)
    elements =
      label_sessions
      |> Enum.filter(fn %LabelSession{elements: elements} ->
        Enum.all?(elements, fn %LabelElement{labels: labels} -> length(labels) > 0 end)
      end)
      |> Enum.map(fn %LabelSession{elements: elements} -> elements end)
      |> Enum.concat()

    compute_results(options, job, elements)
  end

  defp compute_results(%ComparisonExhaustiveOptions{} = options, %LabelJob{} = job, elements) when is_list(elements) do
    objects =
      job.blueprint.elements
      |> Enum.map(fn %LabelElement{objects: objects} -> objects end)
      |> Enum.concat()
      |> Enum.uniq()

    objects_wld = Map.new(objects, fn %Object{} = object ->
      {object.id, {object, 0, 0, 0}}
    end)

    elements
    |> Enum.reduce(objects_wld, fn %LabelElement{} = element, acc ->
      if length(element.labels) > 0 do
        label_option = hd(element.labels).value.option
        [obj1, obj2] = element.objects

        cond do
          # First Object Won
          label_option == Enum.at(options.comparison_label_options, 0) ->
            acc
            |> Map.update!(obj1.id, fn {obj, w, l, d} -> {obj, w + 1, l, d} end)
            |> Map.update!(obj2.id, fn {obj, w, l, d} -> {obj, w, l + 1, d} end)

          # Second Object Won
          label_option == Enum.at(options.comparison_label_options, 1) ->
            acc
            |> Map.update!(obj1.id, fn {obj, w, l, d} -> {obj, w, l + 1, d} end)
            |> Map.update!(obj2.id, fn {obj, w, l, d} -> {obj, w + 1, l, d} end)

          # Draw
          true ->
            acc
            |> Map.update!(obj1.id, fn {obj, w, l, d} -> {obj, w, l, d + 1} end)
            |> Map.update!(obj2.id, fn {obj, w, l, d} -> {obj, w, l, d + 1} end)
        end
      else
        acc
      end
    end)
    |> Enum.map(fn {_id, tuple} -> tuple end)
    |> Enum.map(fn {obj, w, l, d} ->
      score = if w + l + d <= 0, do: 0, else: w / (w + l + d)
      {obj, w, l, d, score}
    end)
    |> Enum.sort(fn tuple1, tuple2 ->
      score1 = elem(tuple1, 4)
      score2 = elem(tuple2, 4)
      score1 <= score2
    end)
    |> Enum.map(fn {%Object{} = obj, w, l, d, score} ->
      {obj, "Score: #{score} (WLD #{w} / #{l} / #{d})"}
    end)
  end

  @impl LabelJobType
  def active?, do: false
end
