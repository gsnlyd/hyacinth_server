defmodule Hyacinth.Assembly.Driver.DicomToNifti do
  alias Hyacinth.Assembly.Driver

  defmodule DicomToNiftiOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :compressed, :boolean, default: true
    end

    @doc false
    def changeset(schema, params) do
      schema
      |> cast(params, [:compressed])
      |> validate_required([:compressed])
    end
  end

  @behaviour Driver

  @impl Driver
  def options_changeset(params), do: DicomToNiftiOptions.changeset(%DicomToNiftiOptions{}, params)

  @impl Driver
  def render_form(assigns) do
    import Phoenix.LiveView.Helpers
    import Phoenix.HTML.Form
    import HyacinthWeb.ErrorHelpers

    ~H"""
    <div class="form-content">
      <p>
        <%= label @form, :compressed %>
        <%= checkbox @form, :compressed %>
        <%= error_tag @form, :compressed %>
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
    args = [
      "-z", "y",
      file_path,
    ]

    {"dcm2niix", args}
  end

  @impl Driver
  def results_glob(_options), do: "**/*.nii.gz"
end
