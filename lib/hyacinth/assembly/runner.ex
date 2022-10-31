defmodule Hyacinth.Assembly.Runner do
  @moduledoc """
  Utilities for running pipelines and transforms.
  """

  require Logger

  alias Hyacinth.{Warehouse, Assembly}

  alias Hyacinth.Warehouse.{Object, Store, Packer}
  alias Hyacinth.Assembly.{Transform, PipelineRun, TransformRun, Driver}

  @type object_tuple :: {String.t, String.t}

  @spec run_command(%Transform{}, %Object{}) :: [map]
  defp run_command(%Transform{} = transform, %Object{} = object) do
    {temp_dir, unpacked_path} = Packer.retrieve_object!(object)
    {command, command_args} = Driver.command_args(transform.driver, transform.options, unpacked_path)

    Logger.debug "Running command #{command} with args: #{command_args}"
    {stdout, exit_code} = System.cmd(command, command_args)
    Logger.debug "Ran command for driver #{transform.driver} with exit code #{exit_code}. Stdout: #{stdout}"

    results_glob_path = Path.join(temp_dir, Driver.results_glob(transform.driver, transform.options))
    results_paths = Path.wildcard(results_glob_path)

    output_format = Driver.output_format(transform.driver, transform.options)

    Enum.map(results_paths, fn path ->
      hash = Store.ingest_file!(path)

      %{
        hash: hash,
        type: :blob,  # TODO: handle tree
        name: Path.relative_to(path, temp_dir),
        format: output_format,
      }
    end)
  end

  @spec run_transform(%TransformRun{}) :: any()
  defp run_transform(%TransformRun{} = transform_run) do
    # Reload transform run to ensure input is loaded
    %TransformRun{} = transform_run = Assembly.get_transform_run!(transform_run.id)
    Logger.debug "Running transform: #{inspect(transform_run)}"

    {:ok, _} = Assembly.start_transform_run(transform_run)

    %Transform{} = transform = transform_run.transform

    objects = Warehouse.list_objects(transform_run.input)
    objects = Driver.filter_objects(transform.driver, transform.options, objects)

    objects_or_params =
      if Driver.pure?(transform.driver) do
        objects
      else
        objects
        |> Enum.map(fn o -> run_command(transform, o) end)
        |> Enum.concat()
      end

    {:ok, result} = Assembly.complete_transform_run(transform_run, objects_or_params)
    Logger.debug inspect(result)

    :ok
  end

  def run_pipeline(%PipelineRun{} = pipeline_run) do
    # Guarantee preloads by reloading
    %PipelineRun{} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)
    Logger.debug "Running pipeline: #{inspect(pipeline_run)}"

    Enum.map(pipeline_run.transform_runs, &run_transform/1)

    :ok
  end
end
