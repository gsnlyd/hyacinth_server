defmodule Hyacinth.Assembly.Driver.Slicer do
  alias Hyacinth.Assembly.Driver

  defmodule SlicerOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :orientation, Ecto.Enum, values: [:sagittal, :coronal, :axial], default: :sagittal
    end

    @doc false
    def changeset(schema, params) do
      schema
      |> cast(params, [:orientation])
      |> validate_required([:orientation])
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
    </div>
    """
  end

  @impl Driver
  def filter_objects(_options, objects), do: objects

  @impl Driver
  def pure?, do: false

  @impl Driver
  def command_args(_options, file_path) do
    binary_path = Application.fetch_env!(:hyacinth, :python_path)
    args = [
      Application.fetch_env!(:hyacinth, :slicer_path),
      file_path,
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
