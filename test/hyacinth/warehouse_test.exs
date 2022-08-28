defmodule Hyacinth.WarehouseTest do
  use Hyacinth.DataCase

  import Hyacinth.WarehouseFixtures

  alias Hyacinth.Warehouse

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
end
