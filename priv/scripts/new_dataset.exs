alias Hyacinth.Warehouse
alias Hyacinth.Warehouse.{Dataset}

require Logger

defmodule Hyacinth.Scripts.NewDataset do
  def get_inputs!() do
    [name, raw_path] = System.argv()
    dataset_path = Path.expand(raw_path)

    {name, dataset_path}
  end

  def get_element_paths(dataset_path) do
    # TODO: support many file types
    dataset_path
    |> File.ls!()
    |> Enum.filter(fn filename -> Path.extname(filename) == ".png" end)
    |> Enum.map(fn filename -> Path.join(dataset_path, filename) end)
  end

  def new_dataset() do
    {name, dataset_path} = get_inputs!()

    element_paths = get_element_paths(dataset_path)
    if length(element_paths) == 0, do: raise "No elements found"

    {:ok, %{dataset: %Dataset{} = dataset, elements: elements}} = Warehouse.create_root_dataset(name, element_paths)

    Logger.info ~s/Created dataset "#{dataset.name}" with #{length(elements)} elements/
  end
end

Hyacinth.Scripts.NewDataset.new_dataset()
