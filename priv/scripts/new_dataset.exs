alias Hyacinth.Warehouse
alias Hyacinth.Warehouse.{Dataset}

require Logger

defmodule Hyacinth.Scripts.NewDataset do
  def get_inputs!() do
    [name, raw_format, raw_path] = System.argv()

    # Note: String.to_atom/1 is generally unsafe because
    # it can crash the VM if the atom limit is hit.
    # However, this is a script, so this is only ever called once.
    format = String.to_atom(raw_format)
    dataset_path = Path.expand(raw_path)

    {name, format, dataset_path}
  end

  def new_dataset() do
    {name, format, dataset_path} = get_inputs!()

    object_tuples =
      case Warehouse.Glob.find_files(dataset_path, format) do
        {:containers, groups} ->
          Enum.map(groups, fn {container_path, child_paths} ->
            child_tuples =
              Enum.map(child_paths, fn path ->
                hash = Warehouse.Store.ingest_file!(path)
                name = Path.relative_to(path, container_path)
                {hash, name}
              end)

            container_hash =
              child_tuples
              |> Enum.map(fn {hash, _name} -> hash end)
              |> Warehouse.Store.hash_hashes()
            container_name = Path.relative_to(container_path, dataset_path)

            {container_hash, container_name, child_tuples}
          end)

        {:files, file_paths} ->
          Enum.map(file_paths, fn path ->
            hash = Warehouse.Store.ingest_file!(path)
            name = Path.relative_to(path, dataset_path)
            {hash, name}
          end)
      end

    if length(object_tuples) == 0, do: raise "No objects found"

    {:ok, %{dataset: %Dataset{} = dataset, objects: objects}} = Warehouse.create_dataset(%{name: name, type: :root}, format, object_tuples)

    Logger.info ~s/Created dataset "#{dataset.name}" with #{length(objects)} objects/
  end
end

Hyacinth.Scripts.NewDataset.new_dataset()
