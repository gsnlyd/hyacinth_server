defmodule Hyacinth.WarehouseTest do
  use Hyacinth.DataCase

  import Hyacinth.WarehouseFixtures

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.Dataset

  @invalid_dataset_attrs %{dataset_type: nil, name: nil}

  describe "list_datasets/0" do
    test "returns all datasets" do
      dataset = dataset_fixture()
      assert Warehouse.list_datasets() == [dataset]
    end
  end

  describe "get_dataset!/1" do
    test "returns the dataset with given id" do
      dataset = dataset_fixture()
      assert Warehouse.get_dataset!(dataset.id) == dataset
    end
  end

  describe "create_dataset/1" do
    test "with valid data creates a dataset" do
      valid_attrs = %{dataset_type: :root, name: "some name"}

      assert {:ok, %Dataset{} = dataset} = Warehouse.create_dataset(valid_attrs)
      assert dataset.dataset_type == :root
      assert dataset.name == "some name"
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Warehouse.create_dataset(@invalid_dataset_attrs)
    end
  end

  describe "update_dataset/2" do
    test "with valid data updates the dataset" do
      dataset = dataset_fixture()
      update_attrs = %{dataset_type: :derived, name: "some updated name"}

      assert {:ok, %Dataset{} = dataset} = Warehouse.update_dataset(dataset, update_attrs)
      assert dataset.dataset_type == :derived
      assert dataset.name == "some updated name"
    end

    test "with invalid data returns error changeset" do
      dataset = dataset_fixture()
      assert {:error, %Ecto.Changeset{}} = Warehouse.update_dataset(dataset, @invalid_dataset_attrs)
      assert dataset == Warehouse.get_dataset!(dataset.id)
    end
  end

  describe "delete_dataset/1" do
    test "deletes the dataset" do
      dataset = dataset_fixture()
      assert {:ok, %Dataset{}} = Warehouse.delete_dataset(dataset)
      assert_raise Ecto.NoResultsError, fn -> Warehouse.get_dataset!(dataset.id) end
    end
  end

  describe "change_dataset/1" do
    test "returns a dataset changeset" do
      dataset = dataset_fixture()
      assert %Ecto.Changeset{} = Warehouse.change_dataset(dataset)
    end
  end
end
