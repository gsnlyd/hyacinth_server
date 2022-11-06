defmodule Hyacinth.IntegrationTest do
  use Hyacinth.DataCase

  import Hyacinth.AccountsFixtures

  alias Hyacinth.{Warehouse, Assembly}
  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.{Dataset, Object, Store}
  alias Hyacinth.Assembly.{Pipeline, PipelineRun, TransformRun, Runner}

  @moduletag :integration

  def clean_test_warehouse(_context) do
    warehouse_glob = Path.join(Application.fetch_env!(:hyacinth, :warehouse_path), "sha256/*")

    # Sanity: hard-code glob path as a precaution
    if warehouse_glob != Path.join(File.cwd!(), "priv/test_storage/warehouse/sha256/*") do
      raise "Invalid warehouse path: #{warehouse_glob}"
    end

    object_paths = Path.wildcard(warehouse_glob)
    Enum.each(object_paths, fn path ->
      # Sanity: ensure object file names look like hashes
      if String.match?(Path.basename(path), ~r/^[0-9a-f]{64}$/) do
        File.rm!(path)
      else
        raise "Cannot clear warehouse - invalid object path: #{path}"
      end
    end)

    :ok
  end

  setup :clean_test_warehouse

  def get_test_dataset_path(), do: Path.join(File.cwd!, "priv/test_data/datasets/test_dataset")

  def object_file_exists?(%Object{hash: hash}), do: File.exists?(Store.get_object_path_from_hash(hash))

  describe "Hyacinth.Warehouse.NewDataset" do
    test "ingests dataset" do
      Warehouse.NewDataset.new_dataset({"TestDicomDataset", "dicom", get_test_dataset_path()})

      datasets = Warehouse.list_datasets()
      assert length(datasets) == 1

      %Dataset{} = dataset = hd(datasets)
      assert dataset.name == "TestDicomDataset"
      assert dataset.type == :root

      objects = Warehouse.list_objects(dataset)
      assert length(objects) == 10

      Enum.each(objects, fn %Object{} = object ->
        assert object.type == :tree
        assert object.format == :dicom
        assert length(object.children) == 100

        Enum.each(object.children, fn %Object{} = child ->
          assert child.type == :blob
          assert child.format == :dicom
        end)
      end)
    end
  end

  @doc """
  Blocks until the given PipelineRun's status is `:complete`.

  You MUST call Assembly.subscribe_pipeline_run_updates/1
  for the given PipelineRun BEFORE calling this function,
  or no updates will be received via PubSub.

  Raises if no message is received after `timeout` ms.
  """
  @spec await_complete(%PipelineRun{}, integer) :: :ok
  def await_complete(%PipelineRun{id: pipeline_run_id} = pipeline_run, timeout) when is_integer(timeout) do
    receive do
      {:pipeline_run_updated, ^pipeline_run_id} ->
        case Assembly.get_pipeline_run!(pipeline_run_id).status do
          :complete ->
            :ok
          _ ->
            await_complete(pipeline_run, timeout)
        end
    after
      timeout -> raise "Timed out while waiting for message"
    end
  end

  describe "Hyacinth.Warehouse.Runner" do
    test "runs 3-step dicom to png pipeline" do
      Warehouse.NewDataset.new_dataset({"TestDicomDataset", "dicom", get_test_dataset_path()})
      [dataset] = Warehouse.list_datasets()

      %User{} = user = user_fixture()

      pipeline_params = %{
        name: "Dicom to PNG test pipeline",
        transforms: [
          %{
            order_index: 0,
            driver: :dicom_to_nifti,
            options: %{},
            input_id: dataset.id,
          },
          %{
            order_index: 1,
            driver: :slicer,
            options: %{},
          },
          %{
            order_index: 2,
            driver: :sample,
            options: %{object_count: 10},
          },
        ]
      }

      {:ok, %Pipeline{} = pipeline} = Assembly.create_pipeline(user, pipeline_params)
      %PipelineRun{} = pipeline_run = Assembly.create_pipeline_run!(pipeline, dataset, user)

      :ok = Assembly.subscribe_pipeline_run_updates(pipeline_run)
      :ok = Runner.run_pipeline(pipeline_run)
      :ok = await_complete(pipeline_run, 30_000)  # This test pipeline should take under 10s to run

      # ---- Check Datasets ----
      [root_ds, nifti_ds, slicer_ds, sample_ds] = Warehouse.list_datasets()

      nifti_objects = Warehouse.list_objects(nifti_ds)
      assert length(nifti_objects) == 10
      Enum.each(nifti_objects, fn %Object{} = o ->
        assert o.type == :blob
        assert o.format == :nifti
        assert object_file_exists?(o)
      end)

      slicer_objects = Warehouse.list_objects(slicer_ds)
      assert length(slicer_objects) == 1000
      Enum.each(slicer_objects, fn %Object{} = o ->
        assert o.type == :blob
        assert o.format == :png
        assert object_file_exists?(o)
      end)

      sample_objects = Warehouse.list_objects(sample_ds)
      assert length(sample_objects) == 10
      Enum.each(sample_objects, fn %Object{} = o ->
        assert o.type == :blob
        assert o.format == :png
        assert object_file_exists?(o)
      end)

      # ---- Check Pipeline Run ----
      %PipelineRun{transform_runs: [tr1, tr2, tr3]} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)

      assert pipeline_run.status == :complete
      assert pipeline_run.completed_at != nil

      assert %TransformRun{} = tr1
      assert tr1.status == :complete
      assert tr1.started_at != nil
      assert tr1.completed_at != nil
      assert tr1.input_id == root_ds.id
      assert tr1.output_id == nifti_ds.id

      assert %TransformRun{} = tr2
      assert tr2.status == :complete
      assert tr2.started_at != nil
      assert tr2.completed_at != nil
      assert tr2.input_id == nifti_ds.id
      assert tr2.output_id == slicer_ds.id

      assert %TransformRun{} = tr3
      assert tr3.status == :complete
      assert tr3.started_at != nil
      assert tr3.completed_at != nil
      assert tr3.input_id == slicer_ds.id
      assert tr3.output_id == sample_ds.id
    end
  end
end
