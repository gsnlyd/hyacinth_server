defmodule Hyacinth.Warehouse.Packer do
  @moduledoc """
  Utilities for retrieving Objects from the object store.

  This module consists of higher-level utilities which work with
  `Hyacinth.Warehouse.Object` structs. See `Hyacinth.Warehouse.Store`
  for lower-level utilities which work directly with individual files.
  """

  require Logger

  alias Hyacinth.Warehouse.{Object, Store}

  @doc """
  Retrieves an Object from the object store. Returns a
  tuple containing the temp dir and the path of the
  retrieved object.

  The retrieved object will be placed in a temporary
  UUID-named directory under the transform temp root.

  If an object is of type :tree with children of type :blob,
  the children will also be retrieved accordingly.
  """
  @spec retrieve_object!(%Object{}) :: {String.t, String.t}
  def retrieve_object!(%Object{} = object) do
    case object.type do
      :tree ->
        temp_dir = Store.create_temp_dir()
        container_path = Path.join(temp_dir, Path.basename(object.name))
        File.mkdir!(container_path)
        Logger.debug "Created container path #{container_path}"

        Enum.each(object.children, fn %Object{} = child_object ->
          dest_path = Path.join(container_path, Path.basename(child_object.name))
          Store.retrieve!(child_object.hash, dest_path)
        end)

        {temp_dir, container_path}

      :blob ->
        temp_dir = Store.create_temp_dir()
        dest_path = Path.join(temp_dir, Path.basename(object.name))
        Store.retrieve!(object.hash, dest_path)

        {temp_dir, dest_path}
    end
  end
end
