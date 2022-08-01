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

  describe "elements" do
    alias Hyacinth.Warehouse.Element

    import Hyacinth.WarehouseFixtures

    @invalid_attrs %{element_type: nil, path: nil}

    test "list_elements/0 returns all elements" do
      element = element_fixture()
      assert Warehouse.list_elements() == [element]
    end

    test "get_element!/1 returns the element with given id" do
      element = element_fixture()
      assert Warehouse.get_element!(element.id) == element
    end

    test "create_element/1 with valid data creates a element" do
      valid_attrs = %{element_type: "some element_type", path: "some path"}

      assert {:ok, %Element{} = element} = Warehouse.create_element(valid_attrs)
      assert element.element_type == "some element_type"
      assert element.path == "some path"
    end

    test "create_element/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Warehouse.create_element(@invalid_attrs)
    end

    test "update_element/2 with valid data updates the element" do
      element = element_fixture()
      update_attrs = %{element_type: "some updated element_type", path: "some updated path"}

      assert {:ok, %Element{} = element} = Warehouse.update_element(element, update_attrs)
      assert element.element_type == "some updated element_type"
      assert element.path == "some updated path"
    end

    test "update_element/2 with invalid data returns error changeset" do
      element = element_fixture()
      assert {:error, %Ecto.Changeset{}} = Warehouse.update_element(element, @invalid_attrs)
      assert element == Warehouse.get_element!(element.id)
    end

    test "delete_element/1 deletes the element" do
      element = element_fixture()
      assert {:ok, %Element{}} = Warehouse.delete_element(element)
      assert_raise Ecto.NoResultsError, fn -> Warehouse.get_element!(element.id) end
    end

    test "change_element/1 returns a element changeset" do
      element = element_fixture()
      assert %Ecto.Changeset{} = Warehouse.change_element(element)
    end
  end
end
