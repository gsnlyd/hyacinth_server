defmodule Hyacinth.Warehouse.FormatType do
  alias Hyacinth.Warehouse.FormatType

  @doc """
  Callback that returns the file extension for this format.

  See extension/1 for details.
  """
  @callback extension() :: String.t

  @doc """
  Returns the file extension for the given format.

  ## Examples

    iex> extension(:png)
    ".png"

    iex> extension(:dicom)
    ".dcm"
  """
  @spec extension(FormatType.t) :: String.t
  def extension(format), do: module_for(format).extension()

  @doc """
  Callback that returns whether this format is a container format.

  See container/1 for details.
  """
  @callback container?() :: boolean

  @doc """
  Returns whether the given format is a container format.
  
  Container formats consist of a directory which contains
  one or more files. These directories are stored as tree
  objects in the warehouse.

  IMPORTANT: The output of extension/1 for a container format
  is the file type of the files WITHIN the container directory!

  ## Examples

    iex> container?(:png)
    false

    iex> container?(:dicom)
    true
  """
  @spec container?(FormatType.t) :: boolean
  def container?(format), do: module_for(format).container?()

  @type t :: :png | :dicom | :dicom_single | :nifti

  @formats [:png, :dicom, :dicom_single, :nifti]
  def list_formats, do: @formats

  defp module_for(:png), do: FormatType.PNG
  defp module_for(:dicom), do: FormatType.DICOM
  defp module_for(:dicom_single), do: FormatType.DICOMSingle
  defp module_for(:nifti), do: FormatType.Nifti
end
