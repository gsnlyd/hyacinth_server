defmodule Hyacinth.Labeling.LabelJobType do
  alias Hyacinth.Labeling.LabelJobType

  alias Hyacinth.Warehouse.Object

  @doc """
  Callback that returns a display name for this job type.

  See `name/1` for details.
  """
  @callback name() :: String.t

  @doc """
  Returns a display name for the given job type.

  ## Examples

      iex> name(:classification)
      "Classification"

      iex> name(:comparison_exhaustive)
      "Comparison (Exhaustive)"

  """
  @spec name(atom) :: String.t
  def name(job_type), do: module_for(job_type).name()

  @doc """
  Callback that returns an options changeset for this job type.

  See `options_changeset/2` for details.
  """
  @callback options_changeset(params :: map) :: %Ecto.Changeset{}

  @doc """
  Returns an options changeset for the given job type.

  ## Examples

      iex> options_changeset(:comparison_exhaustive, %{})
      %Ecto.Changeset{...}

  """
  @spec options_changeset(atom, map) :: %Ecto.Changeset{}
  def options_changeset(job_type, params), do: module_for(job_type).options_changeset(params)

  @doc """
  Callback for a Phoenix function component which renders an
  options form for this job type.

  See `render_form/1` for details.
  """
  @callback render_form(assigns :: map) :: term

  @doc ~S'''
  Phoenix function component which renders an options form for the
  given job type.

  The `assigns` map must contain the following keys:

    * `job_type` - the job type
    * `form` - the `Phoenix.HTML.Form` to render fields for

  ## Examples

      def some_component(assigns) do
        assign(assigns, :my_changeset, options_changeset(:classification, %{})

        ~H"""
        <.form let={f} changeset={@my_changeset}>
          <.render_form job_type={:classification} form={f} />
          <%= submit, "Save" %>
        </.form>
        """
      end

  '''
  @spec render_form(%{job_type: atom, form: %Phoenix.HTML.Form{}}) :: term
  def render_form(assigns), do: module_for(assigns.job_type).render_form(assigns)

  @doc """
  Callback that groups objects for this job type.

  See `group_objects/2` for details.
  """
  @callback group_objects(options :: map, objects :: [%Object{}]) :: [[%Object{}]]

  @doc """
  Groups objects according to the given job type's behavior.

  For example, :comparison_exhaustive groups objects into
  an exhaustive list of pairs (combinations).

  ## Examples

      iex> group_objects(:classification, [obj1, obj2, obj3])
      [[%Object{}], [%Object{}], [%Object{}]]

      iex> group_objects(:comparison_exhaustive, [obj1, obj2, obj3])
      [[...], [...], [...]]

  """
  @spec group_objects(atom, map, [%Object{}]) :: [[%Object{}]]
  def group_objects(job_type, options, objects), do: module_for(job_type).group_objects(options, objects)

  @doc """
  Callback that lists object label options for this job type.

  See `list_object_label_options/2` for details.
  """
  @callback list_object_label_options(options :: map) :: [String.t] | nil

  @doc """
  Lists object label options for the given job type.

  Object label options are the label option values which
  are set when a user chooses a particular object in
  a comparison.

  This functionality is not implemented for all job types.
  In this case, the return value will be nil.

  ## Examples

      iex> list_object_label_options(:comparison_exhaustive, some_options)
      ["First Image", "Second Image"]

      iex> list_object_label_options(:classification, some_options)
      nil

  """
  @spec list_object_label_options(atom, map) :: [String.t] | nil
  def list_object_label_options(job_type, options), do: module_for(job_type).list_object_label_options(options)

  defp module_for(:classification), do: LabelJobType.Classification
  defp module_for(:comparison_exhaustive), do: LabelJobType.ComparisonExhaustive
end
