alias Hyacinth.Warehouse
alias Hyacinth.Warehouse.{Dataset}

require Logger

defmodule Hyacinth.Scripts.NewDataset do
  def get_inputs!() do
    [name, raw_path] = System.argv()
    dataset_path = Path.expand(raw_path)

    {name, dataset_path}
  end

  def get_object_paths(dataset_path) do
    # TODO: support many file types
    dataset_path
    |> File.ls!()
    |> Enum.filter(fn filename -> Path.extname(filename) == ".png" end)
    |> Enum.map(fn filename -> Path.join(dataset_path, filename) end)
  end

  def new_dataset() do
    {name, dataset_path} = get_inputs!()

    object_paths = get_object_paths(dataset_path)
    if length(object_paths) == 0, do: raise "No objects found"

    object_tuples = Enum.map(object_paths, fn path ->
      hash = Warehouse.Store.ingest_file!(path)
      rel_path = Path.relative_to(path, dataset_path)

      {rel_path, hash}
    end)

    {:ok, %{dataset: %Dataset{} = dataset, objects: objects}} = Warehouse.create_root_dataset(name, object_tuples)

    Logger.info ~s/Created dataset "#{dataset.name}" with #{length(objects)} objects/
  end
end

Hyacinth.Scripts.NewDataset.new_dataset()
