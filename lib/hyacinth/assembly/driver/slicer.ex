defmodule Hyacinth.Assembly.Driver.Slicer do
  alias Hyacinth.Assembly.Driver

  defmodule SlicerOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :orientation, Ecto.Enum, values: [:sagittal, :coronal, :axial], default: :sagittal
      field :bit_depth, Ecto.Enum, values: [:"8bit", :"16bit"], default: :"8bit"
      field :tone_map, Ecto.Enum, values: [:disabled, :linear], default: :linear
      field :max_clamp_percentile, :integer, default: 99
    end

    @doc false
    def changeset(schema, params) do
      schema
      |> cast(params, [:orientation, :bit_depth, :tone_map, :max_clamp_percentile])
      |> validate_required([:orientation, :bit_depth, :tone_map, :max_clamp_percentile])
      |> validate_number(:max_clamp_percentile, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    end

    @doc false
    def parse(params) do
      %SlicerOptions{}
      |> changeset(params)
      |> apply_changes()
    end
  end

  @behaviour Driver

  @impl Driver
  def options_changeset(params), do: SlicerOptions.changeset(%SlicerOptions{}, params)

  @impl Driver
  def render_form(assigns) do
    import Phoenix.LiveView.Helpers
    import Phoenix.HTML.Form
    import HyacinthWeb.ErrorHelpers

    ~H"""
    <div class="form-content">
      <p>
        <%= label @form, :orientation %>
        <%= select @form, :orientation, Ecto.Enum.values(SlicerOptions, :orientation) %>
        <%= error_tag @form, :orientation %>
      </p>

      <p>
        <%= label @form, :bit_depth %>
        <%= select @form, :bit_depth, Ecto.Enum.values(SlicerOptions, :bit_depth) %>
        <%= error_tag @form, :bit_depth %>
      </p>

      <p>
        <%= label @form, :tone_map %>
        <%= select @form, :tone_map, Ecto.Enum.values(SlicerOptions, :tone_map) %>
        <%= error_tag @form, :tone_map %>
      </p>

      <p>
        <%= label @form, :max_clamp_percentile %>
        <%= number_input @form, :max_clamp_percentile %>
        <%= error_tag @form, :max_clamp_percentile %>
      </p>
    </div>
    """
  end

  @impl Driver
  def filter_objects(_options, objects), do: objects

  @impl Driver
  def pure?, do: false

  @impl Driver
  def command_args(options, file_path) do
    options = SlicerOptions.parse(options)

    binary_path = Application.fetch_env!(:hyacinth, :python_path)
    args = [
      Application.fetch_env!(:hyacinth, :slicer_path),
      file_path,
      Atom.to_string(options.orientation),
      Atom.to_string(options.bit_depth),
      Atom.to_string(options.tone_map),
      Integer.to_string(options.max_clamp_percentile),
    ]

    {binary_path, args}
  end

  @impl Driver
  def results_glob(_options), do: "output/*.png"

  @impl Driver
  def input_format(_options), do: :nifti

  @impl Driver
  def output_format(_options), do: :png
end
