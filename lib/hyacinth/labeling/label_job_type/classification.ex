defmodule Hyacinth.Labeling.LabelJobType.Classification do
  alias Hyacinth.Labeling.LabelJobType
  alias Hyacinth.Warehouse.Object

  defmodule ClassificationOptions do
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
  def name, do: "Classification"

  @impl LabelJobType
  def options_changeset(params), do: ClassificationOptions.changeset(%ClassificationOptions{}, params)

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
    Enum.map(objects, fn %Object{} = o ->
      [o]
    end)
  end

  @impl LabelJobType
  def list_object_label_options(_options), do: nil
end
