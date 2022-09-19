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
    <div class="form-content">
      <p>
        <%= label @form, :object_count %>
        <%= number_input @form, :object_count %>
        <%= error_tag @form, :object_count %>
      </p>

      <p>
        <%= label @form, :random_seed %>
        <%= number_input @form, :random_seed %>
        <%= error_tag @form, :random_seed %>
      </p>
    </div>
    """
  end

  @impl Driver
  def filter_objects(options, objects) do
    # TODO: use seed
    Enum.take_random(objects, options["object_count"])
  end

  @impl Driver
  def pure?, do: true
end
