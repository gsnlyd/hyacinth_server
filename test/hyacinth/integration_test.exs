defmodule Hyacinth.IntegrationTest do
  use Hyacinth.DataCase

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.{Dataset, Object}

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

  describe "Hyacinth.Warehouse.NewDataset" do
    test "ingests dataset" do
      dataset_path = Path.join(File.cwd!(), "priv/test_data/datasets/test_dataset")
      Warehouse.NewDataset.new_dataset({"TestDicomDataset", "dicom", dataset_path})

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
end
