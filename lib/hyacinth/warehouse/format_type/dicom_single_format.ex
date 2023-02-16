defmodule Hyacinth.Warehouse.FormatType.DICOMSingle do
  alias Hyacinth.Warehouse.FormatType

  @behaviour FormatType

  @impl FormatType
  def extension, do: ".dcm"

  @impl FormatType
  def container?, do: false
end
