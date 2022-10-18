defmodule Hyacinth.Assembly.Runner do
  @moduledoc """
  Utilities for running pipelines and transforms.
  """

  require Logger

  alias Hyacinth.{Warehouse, Assembly}

  alias Hyacinth.Warehouse.{Object, Store, Packer}
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  @type object_tuple :: {String.t, String.t}

  @spec run_command(%Transform{}, %Object{}) :: [map]
  defp run_command(%Transform{} = transform, %Object{} = object) do
    {temp_dir, unpacked_path} = Packer.retrieve_object!(object)
    {command, command_args} = Driver.command_args(transform.driver, transform.arguments, unpacked_path)

    Logger.debug "Running command #{command} with args: #{command_args}"
    {stdout, exit_code} = System.cmd(command, command_args)
    Logger.debug "Ran command for driver #{transform.driver} with exit code #{exit_code}. Stdout: #{stdout}"

    results_glob_path = Path.join(temp_dir, Driver.results_glob(transform.driver, transform.arguments))
    results_paths = Path.wildcard(results_glob_path)

    output_format = Driver.output_format(transform.driver, transform.arguments)

    Enum.map(results_paths, fn path ->
      hash = Store.ingest_file!(path)

      %{
        hash: hash,
        type: :blob,  # TODO: handle tree
        name: Path.relative_to(path, temp_dir),
        file_type: output_format,
      }
    end)
  end

  @spec run_transform(transform :: %Transform{}) :: any()
  def run_transform(%Transform{} = transform) do
    Logger.debug "Running transform #{inspect(transform)}"

    # Reload transform to ensure input is loaded
    %Transform{} = transform = Assembly.get_transform_with_datasets(transform.id)

    if transform.input_id == nil, do: raise "Transform has no input dataset"
    if transform.output_id != nil, do: raise "Transform already has output dataset"

    objects = Warehouse.list_objects(transform.input)
    objects = Driver.filter_objects(transform.driver, transform.arguments, objects)

    objects_or_params =
      if Driver.pure?(transform.driver) do
        objects
      else
        objects
        |> Enum.map(fn o -> run_command(transform, o) end)
        |> Enum.concat()
      end

    IO.inspect Assembly.complete_transform(transform, objects_or_params)
  end

  def run_pipeline(%Pipeline{} = pipeline) do
    Logger.debug "Running pipeline #{inspect(pipeline)}"

    transforms = Assembly.list_transforms(pipeline)
    Enum.map(transforms, &run_transform/1)
  end
end
