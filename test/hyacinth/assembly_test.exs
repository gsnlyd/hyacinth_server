defmodule Hyacinth.AssemblyTest do
  use Hyacinth.DataCase

  import Hyacinth.{AccountsFixtures, WarehouseFixtures, AssemblyFixtures}

  alias Hyacinth.{Assembly}

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.{Pipeline, Transform, PipelineRun, TransformRun}

  describe "list_pipelines_preloaded/0" do
    test "returns the list of pipelines" do
      pipeline_fixture()
      pipeline_fixture()
      pipeline_fixture()

      pipelines = Assembly.list_pipelines_preloaded()
      assert length(pipelines) == 3

      Enum.each(pipelines, fn %Pipeline{} = p ->
        assert Ecto.assoc_loaded?(p.creator)
        assert Ecto.assoc_loaded?(p.transforms)
        assert Ecto.assoc_loaded?(p.runs)
      end)
    end

    test "returns empty list if there are no pipelines" do
      assert Assembly.list_pipelines_preloaded() == []
    end
  end

  describe "get_pipeline!/1" do
    test "returns pipeline if it exists" do
      pipeline = pipeline_fixture()
      assert (%Pipeline{} = Assembly.get_pipeline!(pipeline.id)).id == pipeline.id
    end

    test "raises if pipeline does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Assembly.get_pipeline!(1)
      end
    end
  end

  describe "get_pipeline_preloaded!/1" do
    test "returns pipeline with preloads" do
      original_pipeline = pipeline_fixture()
      pipeline_run_fixture(original_pipeline)

      %Pipeline{} = pipeline = Assembly.get_pipeline_preloaded!(original_pipeline.id)
      assert pipeline.id == original_pipeline.id
      assert Ecto.assoc_loaded?(pipeline.creator)
      assert Ecto.assoc_loaded?(pipeline.transforms)
      assert Ecto.assoc_loaded?(pipeline.runs)

      %PipelineRun{} = pr = hd(pipeline.runs)
      assert Ecto.assoc_loaded?(pr.ran_by)
      assert Ecto.assoc_loaded?(pr.transform_runs)

      %TransformRun{} = tr = hd(pr.transform_runs)
      assert Ecto.assoc_loaded?(tr.input)
      assert Ecto.assoc_loaded?(tr.output)
    end

    test "raises if pipeline does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Assembly.get_pipeline_preloaded!(1)
      end
    end
  end

  describe "create_pipeline/4" do
    test "correctly creates a pipeline" do
      %User{} = user = user_fixture()

      params = %{
        name: "Some Pipeline",
        transforms: [
          %{
            order_index: 0,
            driver: :slicer,
            options: %{orientation: :axial},
          },
          %{
            order_index: 1,
            driver: :sample,
            options: %{object_count: 100},
          },
        ],
      }

      {:ok, %Pipeline{} = pipeline} = Assembly.create_pipeline(user, params)
      assert pipeline.name == "Some Pipeline"
      assert pipeline.creator_id == user.id

      [%Transform{} = transform1, %Transform{} = transform2] = Assembly.list_transforms(pipeline)
      assert transform1.order_index == 0
      assert transform1.driver == :slicer
      assert transform1.options["orientation"] == "axial"

      assert transform2.order_index == 1
      assert transform2.driver == :sample
      assert transform2.options["object_count"] == 100
    end

    test "error if transforms are out of order" do
      %User{} = user = user_fixture()
      %Dataset{} = dataset = root_dataset_fixture()

      params = %{
        name: "Some Pipeline",
        transforms: [
          %{order_index: 0, driver: :slicer, options: %{}, input_id: dataset.id},
          %{order_index: 2, driver: :sample, options: %{}},
        ],
      }

      {:error, %Ecto.Changeset{} = changeset} = Assembly.create_pipeline(user, params)
      assert changeset.errors == [transforms: {"can't be out of order", []}]
    end

    test "error if options are invalid" do
      %User{} = user = user_fixture()
      %Dataset{} = dataset = root_dataset_fixture()

      params = %{
        name: "Some Pipeline",
        transforms: [
          %{order_index: 0, driver: :slicer, options: %{orientation: "invalid value"}, input_id: dataset.id},
          %{order_index: 1, driver: :sample, options: %{}},
        ],
      }

      {:error, %Ecto.Changeset{} = changeset} = Assembly.create_pipeline(user, params)

      refute changeset.valid?
      refute Enum.at(changeset.changes.transforms, 0).valid?
      assert Enum.at(changeset.changes.transforms, 1).valid?

      assert changeset.errors == []
      assert Enum.at(changeset.changes.transforms, 0).errors == [options: {"options are not valid for driver slicer", []}]
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

  describe "get_pipeline_run!/1" do
    test "gets a single pipeline run with preloads" do
      original_pr = pipeline_run_fixture()
      %PipelineRun{} = pipeline_run = Assembly.get_pipeline_run!(original_pr.id)

      assert pipeline_run.id == original_pr.id
      assert Ecto.assoc_loaded?(pipeline_run.pipeline)
      assert Ecto.assoc_loaded?(pipeline_run.transform_runs)

      Enum.each(pipeline_run.transform_runs, fn %TransformRun{} = transform_run ->
        assert Ecto.assoc_loaded?(transform_run.input)
        assert Ecto.assoc_loaded?(transform_run.output)
      end)
    end
  end

  describe "create_pipeline_run!/3" do
    test "creates a pipeline run" do
      pipeline = pipeline_fixture()
      dataset = root_dataset_fixture()
      user = user_fixture()

      pipeline_run = Assembly.create_pipeline_run!(pipeline, dataset, user)
      %PipelineRun{} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)

      assert pipeline_run.status == :running
      assert pipeline_run.completed_at == nil
      assert pipeline_run.ran_by_id == user.id
      assert pipeline_run.pipeline_id == pipeline.id

      [%Transform{} = t1, %Transform{} = t2] = Assembly.list_transforms(pipeline)
      [%TransformRun{} = tr1, %TransformRun{} = tr2] = pipeline_run.transform_runs

      assert tr1.order_index == 0
      assert tr1.status == :waiting
      assert tr1.started_at == nil
      assert tr1.completed_at == nil
      assert tr1.input_id == dataset.id
      assert tr1.output_id == nil
      assert tr1.transform_id == t1.id
      assert tr1.pipeline_run_id == pipeline_run.id

      assert tr2.order_index == 1
      assert tr2.status == :waiting
      assert tr2.started_at == nil
      assert tr2.completed_at == nil
      assert tr2.input_id == nil
      assert tr2.output_id == nil
      assert tr2.transform_id == t2.id
      assert tr2.pipeline_run_id == pipeline_run.id
    end
  end

  describe "list_transform_runs/1" do
    test "lists transform runs for pipeline run" do
      pipeline_run = pipeline_run_fixture()
      [%TransformRun{}, %TransformRun{}] = Assembly.list_transform_runs(pipeline_run)
    end
  end

  describe "get_transform_run!/1" do
    test "gets a single transform run" do
      [original_tr, _] = pipeline_run_fixture().transform_runs
      %TransformRun{} = transform_run = Assembly.get_transform_run!(original_tr.id)

      assert transform_run.id == original_tr.id
      assert Ecto.assoc_loaded?(transform_run.input)
      assert Ecto.assoc_loaded?(transform_run.output)
      assert Ecto.assoc_loaded?(transform_run.transform)
    end
  end

  describe "start_transform_run/1 and complete_transform_run/2" do
    test "correctly starts and completes transforms and completes pipeline" do
      dataset1 = root_dataset_fixture()
      pipeline_run = pipeline_run_fixture(nil, dataset1)

      # ---- Initial State ----
      %PipelineRun{transform_runs: [tr1, tr2]} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)

      assert %TransformRun{} = tr1
      assert tr1.status == :waiting
      assert tr1.started_at == nil
      assert tr1.completed_at == nil
      assert tr1.input_id == dataset1.id
      assert tr1.output_id == nil

      assert %TransformRun{} = tr2
      assert tr2.status == :waiting
      assert tr2.started_at == nil
      assert tr2.completed_at == nil
      assert tr2.input_id == nil
      assert tr2.output_id == nil

      assert pipeline_run.status == :running
      assert pipeline_run.completed_at == nil

      # ---- Start TR1 ----
      {:ok, _} = Assembly.start_transform_run(tr1)

      %PipelineRun{transform_runs: [tr1, tr2]} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)

      assert %TransformRun{} = tr1
      assert tr1.status == :running
      assert tr1.started_at != nil
      assert tr1.completed_at == nil
      assert tr1.input_id == dataset1.id
      assert tr1.output_id == nil

      assert %TransformRun{} = tr2
      assert tr2.status == :waiting
      assert tr2.started_at == nil
      assert tr2.completed_at == nil
      assert tr2.input_id == nil
      assert tr2.output_id == nil

      assert pipeline_run.status == :running
      assert pipeline_run.completed_at == nil

      # ---- Complete TR1 ----
      {:ok, %{dataset: %Dataset{} = dataset2}} = Assembly.complete_transform_run(tr1, many_object_params_fixtures(10, "img", :png))

      %PipelineRun{transform_runs: [tr1, tr2]} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)

      assert %TransformRun{} = tr1
      assert tr1.status == :complete
      assert tr1.started_at != nil
      assert tr1.completed_at != nil
      assert tr1.input_id == dataset1.id
      assert tr1.output_id == dataset2.id

      assert %TransformRun{} = tr2
      assert tr2.status == :waiting
      assert tr2.started_at == nil
      assert tr2.completed_at == nil
      assert tr2.input_id == dataset2.id
      assert tr2.output_id == nil

      assert pipeline_run.status == :running
      assert pipeline_run.completed_at == nil

      # ---- Start TR2 ----
      {:ok, _} = Assembly.start_transform_run(tr2)

      %PipelineRun{transform_runs: [tr1, tr2]} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)

      assert %TransformRun{} = tr1
      assert tr1.status == :complete
      assert tr1.started_at != nil
      assert tr1.completed_at != nil
      assert tr1.input_id == dataset1.id
      assert tr1.output_id == dataset2.id

      assert %TransformRun{} = tr2
      assert tr2.status == :running
      assert tr2.started_at != nil
      assert tr2.completed_at == nil
      assert tr2.input_id == dataset2.id
      assert tr2.output_id == nil

      assert pipeline_run.status == :running
      assert pipeline_run.completed_at == nil

      # ---- Complete TR2 ----
      {:ok, %{dataset: %Dataset{} = dataset3}} = Assembly.complete_transform_run(tr2, many_object_params_fixtures(3, "img", :png))

      %PipelineRun{transform_runs: [tr1, tr2]} = pipeline_run = Assembly.get_pipeline_run!(pipeline_run.id)

      assert %TransformRun{} = tr1
      assert tr1.status == :complete
      assert tr1.started_at != nil
      assert tr1.completed_at != nil
      assert tr1.input_id == dataset1.id
      assert tr1.output_id == dataset2.id

      assert %TransformRun{} = tr2
      assert tr2.status == :complete
      assert tr2.started_at != nil
      assert tr2.completed_at != nil
      assert tr2.input_id == dataset2.id
      assert tr2.output_id == dataset3.id

      assert pipeline_run.status == :complete
      assert pipeline_run.completed_at != nil
    end
  end

  describe "subscribe_pipeline_run_updates/1" do
    test "correctly subscribes to pipeline" do
      %Pipeline{} = pipeline = pipeline_fixture()
      %PipelineRun{} = run1 = pipeline_run_fixture(pipeline)
      %PipelineRun{} = run2 = pipeline_run_fixture(pipeline)

      :ok = Assembly.subscribe_pipeline_run_updates(pipeline)

      :ok = Assembly.broadcast_pipeline_run_update(run1)
      run1_id = run1.id
      assert_received {:pipeline_run_updated, ^run1_id}

      :ok = Assembly.broadcast_pipeline_run_update(run2)
      run2_id = run2.id
      assert_received {:pipeline_run_updated, ^run2_id}
    end

    test "correctly subscribes to pipeline run" do
      %PipelineRun{} = pipeline_run = pipeline_run_fixture()

      :ok = Assembly.subscribe_pipeline_run_updates(pipeline_run)
      :ok = Assembly.broadcast_pipeline_run_update(pipeline_run)

      pipeline_run_id = pipeline_run.id
      assert_received {:pipeline_run_updated, ^pipeline_run_id}
    end
  end

  describe "start_transform_run/1" do
    test "broadcasts PubSub update" do
      %PipelineRun{} = pipeline_run = pipeline_run_fixture()
      [tr1, _] = pipeline_run.transform_runs

      :ok = Assembly.subscribe_pipeline_run_updates(pipeline_run)
      {:ok, _} = Assembly.start_transform_run(tr1)

      pipeline_run_id = pipeline_run.id
      assert_received {:pipeline_run_updated, ^pipeline_run_id}
    end

    test "fails if transform is running" do
      [tr1, _] = pipeline_run_fixture().transform_runs
      {:ok, _} = Assembly.start_transform_run(tr1)
      {:error, :validate_transform_waiting, :running, _changes} = Assembly.start_transform_run(tr1)
    end

    test "fails if transform is complete" do
      [tr1, _] = pipeline_run_fixture().transform_runs
      {:ok, _} = Assembly.start_transform_run(tr1)
      {:ok, _} = Assembly.complete_transform_run(tr1, many_object_params_fixtures())
      {:error, :validate_transform_waiting, :complete, _changes} = Assembly.start_transform_run(tr1)
    end

    test "fails if previous transform is waiting" do
      [_, tr2] = pipeline_run_fixture().transform_runs
      {:error, :validate_previous_transforms_complete, False, _changes} = Assembly.start_transform_run(tr2)
    end

    test "fails if previous transform is running" do
      [tr1, tr2] = pipeline_run_fixture().transform_runs
      {:ok, _} = Assembly.start_transform_run(tr1)
      {:error, :validate_previous_transforms_complete, False, _changes} = Assembly.start_transform_run(tr2)
    end

    test "fails if pipeline is not running" do
      pipeline_run = pipeline_run_fixture()
      [tr1, _] = pipeline_run.transform_runs

      Hyacinth.Repo.update! Ecto.Changeset.change(pipeline_run, %{status: :failed})

      {:error, :validate_pipeline_running, :failed, _changes} = Assembly.start_transform_run(tr1)
    end
  end

  describe "complete_transform_run/2" do
    test "broadcasts PubSub update" do
      %PipelineRun{} = pipeline_run = pipeline_run_fixture()
      [tr1, _] = pipeline_run.transform_runs
      {:ok, _} = Assembly.start_transform_run(tr1)

      :ok = Assembly.subscribe_pipeline_run_updates(pipeline_run)
      {:ok, _} = Assembly.complete_transform_run(tr1, many_object_params_fixtures())

      pipeline_run_id = pipeline_run.id
      assert_received {:pipeline_run_updated, ^pipeline_run_id}
    end

    test "fails if transform is waiting" do
      [tr1, _] = pipeline_run_fixture().transform_runs
      {:error, :validate_transform_running, :waiting, _changes} = Assembly.complete_transform_run(tr1, many_object_params_fixtures())
    end

    test "fails if transform is complete" do
      [tr1, _] = pipeline_run_fixture().transform_runs
      {:ok, _} = Assembly.start_transform_run(tr1)
      {:ok, _} = Assembly.complete_transform_run(tr1, many_object_params_fixtures())
      {:error, :validate_transform_running, :complete, _changes} = Assembly.complete_transform_run(tr1, many_object_params_fixtures())
    end

    test "fails if pipeline is not running" do
      pipeline_run = pipeline_run_fixture()
      [tr1, _] = pipeline_run.transform_runs

      {:ok, _} = Assembly.start_transform_run(tr1)
      Hyacinth.Repo.update! Ecto.Changeset.change(pipeline_run, %{status: :failed})

      {:error, :validate_pipeline_running, :failed, _changes} = Assembly.complete_transform_run(tr1, many_object_params_fixtures())
    end
  end
end
