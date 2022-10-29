defmodule Hyacinth.IntegrationTest do
  use Hyacinth.DataCase

  import Hyacinth.AccountsFixtures

  alias Hyacinth.{Warehouse, Assembly}
  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.{Dataset, Object, Store}
  alias Hyacinth.Assembly.{Pipeline, Runner}

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
        assert object.file_type == :dicom
        assert length(object.children) == 100

        Enum.each(object.children, fn %Object{} = child ->
          assert child.type == :blob
          assert child.file_type == :dicom
        end)
      end)
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
            arguments: %{},
            input_id: dataset.id,
          },
          %{
            order_index: 1,
            driver: :slicer,
            arguments: %{},
          },
          %{
            order_index: 2,
            driver: :sample,
            arguments: %{object_count: 10},
          },
        ]
      }

      {:ok, %Pipeline{} = pipeline} = Assembly.create_pipeline(user, pipeline_params)
      Runner.run_pipeline(pipeline)

      [_root_ds, nifti_ds, slicer_ds, sample_ds] = Warehouse.list_datasets()

      nifti_objects = Warehouse.list_objects(nifti_ds)
      assert length(nifti_objects) == 10
      Enum.each(nifti_objects, fn %Object{} = o ->
        assert o.type == :blob
        assert o.file_type == :nifti
        assert object_file_exists?(o)
      end)

      slicer_objects = Warehouse.list_objects(slicer_ds)
      assert length(slicer_objects) == 1000
      Enum.each(slicer_objects, fn %Object{} = o ->
        assert o.type == :blob
        assert o.file_type == :png
        assert object_file_exists?(o)
      end)

      sample_objects = Warehouse.list_objects(sample_ds)
      assert length(sample_objects) == 10
      Enum.each(sample_objects, fn %Object{} = o ->
        assert o.type == :blob
        assert o.file_type == :png
        assert object_file_exists?(o)
      end)
    end
  end
end
