defmodule Hyacinth.Warehouse.FormatType.DICOM do
  alias Hyacinth.Warehouse.FormatType

  @behaviour FormatType

  @impl FormatType
  def extension, do: ".dcm"

  @impl FormatType
  def container?, do: true
end
