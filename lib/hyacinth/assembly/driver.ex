defmodule Hyacinth.Assembly.Driver do
  alias Hyacinth.Assembly.Driver

  alias Hyacinth.Warehouse.{Object}

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

  The `assigns` map must contain the following keys:

    * `driver` - the driver to render the form for.
    * `transform_index` - a unique index which is returned as a parameter when the form
    is changed. Also used to set the id of the form preventing conflicts in the DOM when
    multiple forms are rendered.
    * `changeset` - the options changeset for the given driver. See `options_changeset/2`
    for details.
    * `change_event` - the LiveView event which will be passed to phx-change on the form.

  ## Examples

      def some_component(assigns) do
        assign(assigns, :my_changeset, options_changeset(:slicer, %{}))

        ~H"""
        <div>
          <.render_form
            driver={:slicer}
            transform_index={0}
            changeset={@my_changeset}
            change_event="my_form_change_event"
          />
        </div>
        """
      end

  '''
  def render_form(assigns), do: module_for(assigns[:driver]).render_form(assigns)

  @doc """
  Callback that returns a list of objects filtered for this driver.

  See `filter_objects/3` for details.
  """
  @callback filter_objects(%{required(atom) => term()}, [%Object{}]) :: [%Object{}]

  @doc """
  Returns a list of objects filtered for the given driver.

  Drivers can implement a filter functionality which subsamples
  the objects from a dataset before transforming them. This could
  be done for any reason, but examples include choosing only objects
  of a given file type which apply to the driver, or implementing a
  driver which efficiently performs pure subsampling of a dataset
  without any further transformation.

  ## Examples

      iex> options = %{...}
      iex> objects = Warehouse.list_objects(my_dataset)
      iex> filter_objects(:sample, options, objects)
      [%Object{}, %Object{}, ...]

  """
  def filter_objects(driver, options, objects) when is_map(options) and is_list(objects) do
    module_for(driver).filter_objects(options, objects)
  end

  defp module_for(:sample), do: Driver.Sample
  defp module_for(:slicer), do: Driver.Slicer
end
