defmodule Hyacinth.Assembly.Runner do
  @moduledoc """
  Utilities for running pipelines and transforms.
  """

  require Logger

  alias Hyacinth.{Warehouse, Assembly}

  alias Hyacinth.Warehouse.{Object, Store, Packer}
  alias Hyacinth.Assembly.{PipelineRun, TransformRun, Driver}

  @type object_tuple :: {String.t, String.t}

  @spec run_command(atom, map, %Object{}) :: [map]
  defp run_command(driver, options, %Object{} = object) when is_atom(driver) and is_map(options) do
    {temp_dir, unpacked_path} = Packer.retrieve_object!(object)
    {command, command_args} = Driver.command_args(driver, options, unpacked_path)

    Logger.debug "Running command #{command} with args: #{command_args}"
    {stdout, exit_code} = System.cmd(command, command_args)
    Logger.debug "Ran command for driver #{driver} with exit code #{exit_code}. Stdout: #{stdout}"

    results_glob_path = Path.join(temp_dir, Driver.results_glob(driver, options))
    results_paths = Path.wildcard(results_glob_path)

    output_format = Driver.output_format(driver, options)

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

  @spec run_transform(%TransformRun{}) :: :ok
  defp run_transform(%TransformRun{} = transform_run) do
    # Reload transform run to ensure input is loaded
    %TransformRun{} = transform_run = Assembly.get_transform_run!(transform_run.id)
    Logger.debug "Running transform: #{inspect(transform_run)}"

    {:ok, _} = Assembly.start_transform_run(transform_run)

    driver = transform_run.transform.driver
    options = transform_run.transform.options

    objects = Warehouse.list_objects(transform_run.input)
    objects = Driver.filter_objects(driver, options, objects)

    objects_or_params =
      if Driver.pure?(driver) do
        objects
      else
        objects
        |> Enum.map(fn o -> run_command(driver, options, o) end)
        |> Enum.concat()
      end

    {:ok, result} = Assembly.complete_transform_run(transform_run, objects_or_params)
    Logger.debug inspect(result)

    :ok
  end

  @doc """
  Runs a pipeline.

  ## Examples

      iex> run_pipeline(some_pipeline_run)
      :ok

  """
  @spec run_pipeline(%PipelineRun{}) :: :ok
  def run_pipeline(%PipelineRun{} = pipeline_run) do
    # Guarantee preloads by reloading
    %PipelineRun{} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)
    Logger.debug "Running pipeline: #{inspect(pipeline_run)}"

    Enum.map(pipeline_run.transform_runs, &run_transform/1)

    :ok
  end
end
