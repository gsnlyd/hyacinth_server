defmodule Hyacinth.WarehouseTest do
  use Hyacinth.DataCase

  import Hyacinth.WarehouseFixtures

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.{Dataset, Object}

  describe "list_datasets/0" do
    test "returns all datasets" do
      dataset = root_dataset_fixture()
      assert Warehouse.list_datasets() == [dataset]
    end
  end

  describe "get_dataset!/1" do
    test "returns the dataset with given id" do
      dataset = root_dataset_fixture()
      assert Warehouse.get_dataset!(dataset.id) == dataset
    end
  end

  describe "create_root_dataset/2" do
    test "creates a root dataset" do
      object_tuples = [
        {"object1.png", hash_fixture("obj1")},
        {"object2.png", hash_fixture("obj2")},
        {"object3.png", hash_fixture("obj3")},
      ]

      {:ok, %{dataset: %Dataset{} = dataset}} = Warehouse.create_root_dataset("Some Dataset", object_tuples)

      assert dataset.name == "Some Dataset"
      assert dataset.type == :root

      objects = Warehouse.list_objects(dataset)
      assert length(objects) == 3
      assert Enum.map(objects, fn %Object{} = o -> o.name end) == ["object1.png", "object2.png", "object3.png"]
      assert Enum.map(objects, fn %Object{} = o -> o.hash end) == [hash_fixture("obj1"), hash_fixture("obj2"), hash_fixture("obj3")]
    end
  end

  describe "list_objects/1" do
    test "returns objects for dataset" do
      dataset = root_dataset_fixture(nil, 10)
      _other_dataset = root_dataset_fixture()

      objects = Warehouse.list_objects(dataset)
      assert length(objects) == 10
    end
  end

  describe "get_object/1" do
    test "returns the object with the given id" do
      _dataset = root_dataset_fixture()

      object = Warehouse.get_object!(1)
      assert %Object{} = object
      assert object.id == 1
    end

    test "raises if object does not exist" do
      _dataset = root_dataset_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Warehouse.get_object!(1000)
      end
    end
  end
end
