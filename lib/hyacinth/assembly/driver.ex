defmodule Hyacinth.Assembly.Driver do
  alias Hyacinth.Assembly.Driver

  alias Hyacinth.Warehouse.{Object}

  @doc """
  Callback that returns an options changeset for this driver.

  See `options_changeset/2` for details.
  """
  @callback options_changeset(params :: %{atom => term} | Keyword.t()) :: %Ecto.Changeset{}

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
  @spec options_changeset(driver :: atom, params :: %{atom => term} | Keyword.t()) :: %Ecto.Changeset{}
  def options_changeset(driver, params \\ %{}), do: module_for(driver).options_changeset(params)

  @doc """
  Callback for a Phoenix function component which returns a rendered
  options form for this driver.

  See `render_form/2` for details.
  """
  @callback render_form(assigns :: %{atom => term}) :: any

  @doc ~S'''
  Phoenix function component which returns rendered options form fields
  for the given driver.

  This function component should be called within a template or LiveView
  to render form fields for the given driver's options.

  The `assigns` map must contain the following keys:

    * `driver` - the driver
    * `form` - the form to render fields for

  ## Examples

      def some_component(assigns) do
        assign(assigns, :my_changeset, options_changeset(:slicer, %{}))

        ~H"""
        <.form let={f} changeset={@my_changeset}>
          <.render_form driver={:slicer} form={f} />
          <%= submit, "Save" %>
        </div>
        """
      end

  '''
  @spec render_form(assigns :: %{atom => term}) :: any
  def render_form(assigns), do: module_for(assigns[:driver]).render_form(assigns)

  @doc """
  Callback that returns a list of objects filtered for this driver.

  See `filter_objects/3` for details.
  """
  @callback filter_objects(options :: %{String.t => term}, objects :: [%Object{}]) :: [%Object{}]

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
  @spec filter_objects(driver :: atom, options :: %{atom => term}, objects :: [%Object{}]) :: [%Object{}]
  def filter_objects(driver, options, objects) when is_map(options) and is_list(objects) do
    module_for(driver).filter_objects(options, objects)
  end

  @doc """
  Callback that returns true if this driver is pure, false otherwise.

  See `pure?/1` for details.
  """
  @callback pure?() :: boolean

  @doc """
  Returns true if the given driver is pure, false otherwise.

  A pure driver is one which only samples existing objects
  and does not create any new objects.

  Pure drivers do NOT have to implement the following functions:

    * `command_args/3`
    * `results_glob/2`

  ## Examples

      iex> pure?(:sample)
      true

      iex> pure?(:slicer)
      false

  """
  @spec pure?(driver :: atom) :: boolean
  def pure?(driver), do: module_for(driver).pure?()

  @doc """
  Callback that returns a command and arguments to run this driver.

  This callback should not be implemented for pure drivers (see `pure?/1`).

  See `command_args/3` for details.
  """
  @callback command_args(options :: %{String.t => term}, file_path :: String.t) :: {String.t, [String.t]}

  @doc """
  Returns a command and arguments to run the given driver.

  This function is not implemented for pure drivers (see `pure?/1`).

  ## Examples

      iex> command_args(:slicer, %{"orientation" => "sagittal"}, "/path/to/img.nii.gz")
      {"/path/to/python", ["/path/to/slicer.py", "/path/to/img.nii.gz"]}

  """
  @spec command_args(driver :: atom, options :: %{String.t => term}, file_path :: String.t) :: {String.t, [String.t]}
  def command_args(driver, options, file_path), do: module_for(driver).command_args(options, file_path)

  @doc """
  Callback that returns a glob which locates the results of this driver.

  This callback should not be implemented for pure drivers (see `pure?/1`).

  See `results_glob/2` for details.
  """
  @callback results_glob(options :: %{String.t => term}) :: String.t

  @doc """
  Returns a glob which locates the results of this driver.

  This function is not implemented for pure drivers (see `pure?/1`).

  ## Examples

      results_glob(:slicer, my_options)
      "output/*.png"

  """
  @spec results_glob(driver :: atom, options :: %{String.t => term}) :: String.t
  def results_glob(driver, options), do: module_for(driver).results_glob(options)

  @doc """
  Callback that returns the input format for this driver with the given options.

  This callback should not be implemented for pure drivers (see `pure?/1`).

  See `input_format/2` for details.
  """
  @callback input_format(options :: map) :: atom

  @doc """
  Returns the input format for the given driver with the given options.

  The returned format can be any valid `Hyacinth.Warehouse.FormatType`
  format.

  This function is not implemented for pure drivers (see `pure?/1`).

  ## Examples

      iex> input_format(:dicom_to_nifti, some_options)
      :dicom

  """
  @spec input_format(atom, map) :: atom
  def input_format(driver, options), do: module_for(driver).input_format(options)

  @doc """
  Callback that returns the output format for this driver with the given options.

  This callback should not be implemented for pure drivers (see `pure?/1`).

  See `output_format/2` for details.
  """
  @callback output_format(options :: map) :: atom

  @doc """
  Returns the output format for the given driver with the given options.

  The returned format can be any valid `Hyacinth.Warehouse.FormatType`
  format.

  This function is not implemented for pure drivers (see `pure?/1`).

  ## Examples

      iex> ouptut_format(:dicom_to_nifti, some_options)
      :nifti

  """
  @spec output_format(atom, map) :: atom
  def output_format(driver, options), do: module_for(driver).output_format(options)


  @optional_callbacks command_args: 2, results_glob: 1, input_format: 1, output_format: 1

  defp module_for(:sample), do: Driver.Sample
  defp module_for(:slicer), do: Driver.Slicer
  defp module_for(:dicom_to_nifti), do: Driver.DicomToNifti

  @doc """
  Converts a string to a driver atom.

  ## Examples

      iex> from_string!("sample")
      :sample

      iex> from_string!("some string")
      ** (ArgumentError) Not a driver: some string
  """
  @spec from_string!(String.t) :: atom
  def from_string!(string) when is_binary(string) do
    case string do
      "sample" -> :sample
      "slicer" -> :slicer
      "dicom_to_nifti" -> :dicom_to_nifti
      _ -> raise ArgumentError, "Not a driver: #{string}"
    end
  end
end
