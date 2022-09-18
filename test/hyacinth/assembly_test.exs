defmodule Hyacinth.AssemblyTest do
  use Hyacinth.DataCase

  import Hyacinth.{AccountsFixtures, WarehouseFixtures, AssemblyFixtures}

  alias Hyacinth.{Warehouse, Assembly}

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  describe "get_pipeline!/1" do
    test "returns pipeline if it exists" do
      pipeline = pipeline_fixture()
      assert Assembly.get_pipeline!(pipeline.id) == pipeline
    end

    test "raises if pipeline does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Assembly.get_pipeline!(1)
      end
    end
  end

  describe "create_pipeline/4" do
    test "correctly creates a pipeline" do
      %User{} = user = user_fixture()
      %Dataset{} = dataset = root_dataset_fixture()

      transform_changesets = [
        {
          Transform.changeset(%Transform{}, %{order_index: 0, driver: :slicer}),
          Driver.options_changeset(:slicer, %{orientation: :axial})
        },
        {
          Transform.changeset(%Transform{}, %{order_index: 0, driver: :sample}),
          Driver.options_changeset(:sample, %{object_count: 100})
        },
      ]

      {:ok, %{pipeline: %Pipeline{} = pipeline}} = Assembly.create_pipeline(user, "Some Pipeline", dataset.id, transform_changesets)
      assert pipeline.name == "Some Pipeline"
      assert pipeline.creator_id == user.id

      [%Transform{} = transform1, %Transform{} = transform2] = Assembly.list_transforms(pipeline)
      assert transform1.order_index == 0
      assert transform1.driver == :slicer
      assert transform1.arguments["orientation"] == "axial"
      assert transform1.input_id == dataset.id
      assert transform1.output_id == nil

      assert transform2.order_index == 1
      assert transform2.driver == :sample
      assert transform2.arguments["object_count"] == 100
      assert transform2.input_id == nil
      assert transform2.output_id == nil
    end
  end

  describe "list_transforms/1" do
    test "returns transforms for pipeline" do
      pipeline = pipeline_fixture()
      [%Transform{} = transform1, %Transform{} = transform2] = Assembly.list_transforms(pipeline)

      assert transform1.pipeline_id == pipeline.id
      assert transform1.order_index == 0

      assert transform2.pipeline_id == pipeline.id
      assert transform2.order_index == 1
    end
  end

  describe "get_transform_with_datasets/1" do
    test "returns transform with datasets preloaded" do
      pipeline = pipeline_fixture()
      transform_id = hd(Assembly.list_transforms(pipeline)).id

      transform = Assembly.get_transform_with_datasets(transform_id)
      assert Ecto.assoc_loaded?(transform.input)
      assert Ecto.assoc_loaded?(transform.output)
    end
  end

  describe "change_transform/2" do
    test "returns changeset for transform" do
      changeset = Assembly.change_transform(%Transform{}, %{order_index: 0, driver: :sample})
      assert %Ecto.Changeset{} = changeset
      assert %Transform{} = changeset.data
    end
  end

  describe "complete_transform/2" do
    test "correctly completes transform" do
      pipeline = pipeline_fixture()
      [%Transform{} = transform1, %Transform{} = transform2] = Assembly.list_transforms(pipeline)

      object_tuples = [
        {hash_fixture("derived_image1"), "path/to/image1.png"},
        {hash_fixture("derived_image2"), "path/to/image2.png"},
        {hash_fixture("derived_image3"), "path/to/image3.png"},
      ]

      assert transform1.input_id != nil
      assert transform1.output_id == nil
      assert transform2.input_id == nil
      assert transform2.output_id == nil
      assert length(Warehouse.list_datasets()) == 1

      {:ok, _changes} = Assembly.complete_transform(transform1, object_tuples)

      [%Transform{} = transform1, %Transform{} = transform2] = Assembly.list_transforms(pipeline)

      assert transform1.input_id != nil
      assert transform1.output_id != nil
      assert transform2.input_id != nil
      assert transform2.output_id == nil
      assert transform1.output_id == transform2.input_id
      assert length(Warehouse.list_datasets()) == 2

      new_dataset = Warehouse.get_dataset!(transform1.output_id)
      assert length(Warehouse.list_objects(new_dataset)) == 3
    end

    test "fails if transform was already run" do
      pipeline = pipeline_fixture()
      transform = hd(Assembly.list_transforms(pipeline))

      object_tuples = [
        {hash_fixture("derived_image1"), "path/to/image1.png"},
        {hash_fixture("derived_image2"), "path/to/image2.png"},
        {hash_fixture("derived_image3"), "path/to/image3.png"},
      ]

      {:ok, _changes} = Assembly.complete_transform(transform, object_tuples)
      {:error, :validate_transform_has_no_output, false, _changes} = Assembly.complete_transform(transform, object_tuples)
    end
  end
end
