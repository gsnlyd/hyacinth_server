defmodule Hyacinth.Warehouse.Glob do
  @moduledoc """
  Utilities for locating files of a particular format within
  a directory. Used to locate files to ingest into the object store
  during dataset creation.
  """

  alias Hyacinth.Warehouse.FormatType

  def find_files(root_path, format) when is_binary(root_path) and is_atom(format) do
    extension = FormatType.extension(format)

    glob_pattern = Path.join([root_path, "**", "*" <> extension])
    file_paths = Path.wildcard(glob_pattern)

    if FormatType.container?(format) do
      groups = Enum.group_by(file_paths, &Path.dirname/1)
      {:containers, groups}
    else
      {:files, file_paths}
    end
  end
end
