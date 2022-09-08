defmodule Hyacinth.Warehouse.FormatType.PNG do
  alias Hyacinth.Warehouse.FormatType

  @behaviour FormatType

  @impl FormatType
  def extension, do: ".png"

  @impl FormatType
  def container?, do: false
end
