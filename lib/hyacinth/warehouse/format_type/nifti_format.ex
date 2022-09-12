defmodule Hyacinth.Warehouse.FormatType.Nifti do
  alias Hyacinth.Warehouse.FormatType

  @behaviour FormatType

  @impl FormatType
  def extension, do: ".nii.gz"

  @impl FormatType
  def container?, do: false
end
