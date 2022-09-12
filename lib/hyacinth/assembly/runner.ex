defmodule Hyacinth.Assembly.Runner do
  @moduledoc """
  Utilities for running pipelines and transforms.
  """

  require Logger

  alias Hyacinth.{Warehouse, Assembly}

  alias Hyacinth.Warehouse.{Object, Store}
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  def run_transform(%Transform{} = transform) do
    Logger.debug "Running transform #{inspect(transform)}"

    if transform.input == nil, do: raise "Transform has no input dataset"
    if transform.output != nil, do: raise "Transform already has output dataset"

    objects = Warehouse.list_objects(transform.input)

    object_tuples =
      Enum.map(objects, fn %Object{} = object ->
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
      |> IO.inspect

    IO.inspect Assembly.complete_transform(transform, object_tuples)
  end

  def run_pipeline(%Pipeline{} = pipeline) do
    Logger.debug "Running pipeline #{inspect(pipeline)}"

    transforms = Assembly.list_transforms(pipeline)
    Enum.map(transforms, &run_transform/1)
  end
end
