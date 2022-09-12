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
    <.form id={"options_form_#{@transform_index}"} let={f} for={@changeset} as="options" phx-change={@change_event}>
      <%= hidden_input f, :transform_index, value: @transform_index %>
      <div class="form-content">
        <p>
          <%= label f, :orientation %>
          <%= select f, :orientation, Ecto.Enum.values(SlicerOptions, :orientation) %>
          <%= error_tag f, :orientation %>
        </p>
      </div>
    </.form>
    """
  end

  @impl Driver
  def filter_objects(_options, objects), do: objects
end
