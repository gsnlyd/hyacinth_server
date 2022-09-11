defmodule Hyacinth.Assembly.Driver do
  alias Hyacinth.Assembly.Driver

  @doc """
  Callback that returns an options changeset for this driver.

  See `options_changeset/2` for details.
  """
  @callback options_changeset(%{required(atom()) => term() | Keyword.t()}) :: binary()

  @doc """
  Returns an options changeset for the given driver.

  Each driver has an Ecto embedded_schema that encodes its options.
  This function returns a changeset which can be used to render
  the form for a `Hyacinth.Assembly.Transform` using the given driver
  and validate its options before inserting.

  ## Examples
    
      iex> options_changeset(:slicer, %{})
      %Ecto.Changeset{...}

  """
  def options_changeset(driver, params \\ %{}), do: module_for(driver).options_changeset(params)

  @doc """
  Callback for a Phoenix function component which returns a rendered
  options form for this driver.

  See `render_form/2` for details.
  """
  @callback render_form(%{required(atom()) => term()}) :: binary()

  @doc ~S'''
  Phoenix function component which returns a rendered options form for the given driver.

  This function component should be called within a template or LiveView
  to render a form for the given driver's options.

  The `assigns` map must contain a driver under the `driver` key
  as well as a changeset under the `changeset` key which will be used to render
  the form.

  See `options_changeset/2` for details on obtaining the changeset.

  ## Examples

      def some_component(assigns) do
        assign(assigns, :my_changeset, options_changeset(:slicer, %{}))

        ~H"""
        <div>
          <.render_form driver={:slicer} changeset={@my_changeset} />
        </div>
        """
      end

  '''
  def render_form(assigns), do: module_for(assigns[:driver]).render_form(assigns)

  defp module_for(:slicer), do: Driver.Slicer
end
