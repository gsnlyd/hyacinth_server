defmodule Hyacinth.WarehouseTest do
  use Hyacinth.DataCase

  alias Hyacinth.Warehouse

  describe "datasets" do
    alias Hyacinth.Warehouse.Dataset

    import Hyacinth.WarehouseFixtures

    @invalid_attrs %{dataset_type: nil, name: nil}

    test "list_datasets/0 returns all datasets" do
      dataset = dataset_fixture()
      assert Warehouse.list_datasets() == [dataset]
    end

    test "get_dataset!/1 returns the dataset with given id" do
      dataset = dataset_fixture()
      assert Warehouse.get_dataset!(dataset.id) == dataset
    end

    test "create_dataset/1 with valid data creates a dataset" do
      valid_attrs = %{dataset_type: :root, name: "some name"}

      assert {:ok, %Dataset{} = dataset} = Warehouse.create_dataset(valid_attrs)
      assert dataset.dataset_type == :root
      assert dataset.name == "some name"
    end

    test "create_dataset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Warehouse.create_dataset(@invalid_attrs)
    end

    test "update_dataset/2 with valid data updates the dataset" do
      dataset = dataset_fixture()
      update_attrs = %{dataset_type: :derived, name: "some updated name"}

      assert {:ok, %Dataset{} = dataset} = Warehouse.update_dataset(dataset, update_attrs)
      assert dataset.dataset_type == :derived
      assert dataset.name == "some updated name"
    end

    test "update_dataset/2 with invalid data returns error changeset" do
      dataset = dataset_fixture()
      assert {:error, %Ecto.Changeset{}} = Warehouse.update_dataset(dataset, @invalid_attrs)
      assert dataset == Warehouse.get_dataset!(dataset.id)
    end

    test "delete_dataset/1 deletes the dataset" do
      dataset = dataset_fixture()
      assert {:ok, %Dataset{}} = Warehouse.delete_dataset(dataset)
      assert_raise Ecto.NoResultsError, fn -> Warehouse.get_dataset!(dataset.id) end
    end

    test "change_dataset/1 returns a dataset changeset" do
      dataset = dataset_fixture()
      assert %Ecto.Changeset{} = Warehouse.change_dataset(dataset)
    end
  end
end
