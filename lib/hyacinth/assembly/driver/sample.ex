defmodule Hyacinth.Assembly.Driver.Sample do
  alias Hyacinth.Assembly.Driver

  defmodule SampleOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :object_count, :integer, default: 20
      field :random_seed, :integer, default: 123
    end

    @doc false
    def changeset(schema, params) do
      schema
      |> cast(params, [:object_count, :random_seed])
      |> validate_required([:object_count, :random_seed])
      |> validate_number(:object_count, greater_than: 0)
    end
  end

  @behaviour Driver

  @impl Driver
  def options_changeset(params), do: SampleOptions.changeset(%SampleOptions{}, params)

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
          <%= label f, :object_count %>
          <%= number_input f, :object_count %>
          <%= error_tag f, :object_count %>
        </p>

        <p>
          <%= label f, :random_seed %>
          <%= number_input f, :random_seed %>
          <%= error_tag f, :random_seed %>
        </p>
      </div>
    </.form>
    """
  end

  @impl Driver
  def filter_objects(_options, objects), do: objects
end
