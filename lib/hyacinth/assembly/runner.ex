defmodule Hyacinth.Assembly.Runner do
  @moduledoc """
  Utilities for running pipelines and transforms.
  """

  require Logger

  alias Hyacinth.{Warehouse, Assembly}

  alias Hyacinth.Warehouse.{Object, Store}
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  @type object_tuple :: {binary, binary}

  @spec run_driver_commands(transform :: %Transform{}, objects :: [%Object{}]) :: [object_tuple]
  defp run_driver_commands(%Transform{} = transform, objects) when is_list(objects) do
    objects
    |> Enum.map(fn %Object{} = object ->
      {temp_dir, unpacked_path} = Store.unpack!(object.hash, Path.basename(object.name))
      {command, command_args} = Driver.command_args(transform.driver, transform.arguments, unpacked_path)

      Logger.debug "Running command #{command} with args: #{command_args}"
      {stdout, exit_code} = System.cmd(command, command_args)
      Logger.debug "Ran command for driver #{transform.driver} with exit code #{exit_code}. Stdout: #{stdout}"

      results_glob_path = Path.join(temp_dir, Driver.results_glob(transform.driver, transform.arguments))
      results_paths = Path.wildcard(results_glob_path)

      Enum.map(results_paths, fn path ->
        hash = Store.ingest_file!(path)
        name = Path.relative_to(path, temp_dir)

        {hash, name}
      end)
    end)
    |> Enum.concat()
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

    object_tuples =
      if Driver.pure?(transform.driver) do
        # TODO: reuse objects instead of creating new ones
        Enum.map(objects, fn %Object{} = object ->
          {object.hash, object.name}
        end)
      else
        run_driver_commands(transform, objects)
      end

    IO.inspect Assembly.complete_transform(transform, object_tuples)
  end

  def run_pipeline(%Pipeline{} = pipeline) do
    Logger.debug "Running pipeline #{inspect(pipeline)}"

    transforms = Assembly.list_transforms(pipeline)
    Enum.map(transforms, &run_transform/1)
  end
end
