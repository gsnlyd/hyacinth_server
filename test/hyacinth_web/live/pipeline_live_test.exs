defmodule HyacinthWeb.PipelineLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.{WarehouseFixtures, AssemblyFixtures}

  alias Hyacinth.Assembly
  alias Hyacinth.Assembly.{Pipeline, Transform}

  setup :register_and_log_in_user

  describe "PipelineLive.Index" do
    test "renders pipelines", %{conn: conn} do
      pipeline_fixture("My First Pipeline")
      pipeline_fixture("My Second Pipeline")
      pipeline_fixture("My Third Pipeline")

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.Index))
      assert html =~ "<h1>Pipelines</h1>"

      assert html =~ "My First Pipeline"
      assert html =~ "My Second Pipeline"
      assert html =~ "My Third Pipeline"
    end

    test "renders with no pipelines", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.Index))
      assert html =~ "<h1>Pipelines</h1>"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.Index))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end

  describe "PipelineLive.New" do
    test "renders page", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))
      assert html =~ "<h1>New Pipeline</h1>"
    end

    test "validate_pipeline event correctly updates page", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))
      _html = render_click(view, :add_transform, %{})
      html = render_click(view, :add_transform, %{})

      refute html =~ ~s(<option selected="selected" value="slicer">)

      params = %{
        "name" => "",
        "transforms" => %{
          "0" => %{"driver" => "slicer", "order_index" => "0"},
          "1" => %{"driver" => "sample", "order_index" => "1"},
        }
      }
      html = render_change(view, :validate_pipeline, %{"pipeline" => params})

      assert html =~ ~s(<option selected="selected" value="slicer">)
      assert html =~ ~s(<option selected="selected" value="sample">)
    end

    test "validate_pipeline event correctly resets transform options for new driver", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))
      render_click(view, :add_transform, %{})

      params = %{
        "name" => "",
        "transforms" => %{
          "0" => %{"driver" => "sample", "order_index" => "0"},
        }
      }
      render_change(view, :validate_pipeline, %{"pipeline" => params})
      send(view.pid, {:update_transform_options, {0, :sample, %{"object_count" => "9876"}}})

      html = render(view)
      assert html =~ ~s(<option selected="selected" value="sample">)
      assert html =~ "Object count:</span><span>9876</span>"

      params = %{
        "name" => "",
        "transforms" => %{
          "0" => %{"driver" => "dicom_to_nifti", "order_index" => "0"},
        }
      }
      html = render_change(view, :validate_pipeline, %{"pipeline" => params})

      assert html =~ ~s(<option selected="selected" value="dicom_to_nifti">)
      refute html =~ ~s(<option selected="selected" value="sample">)
      refute html =~ "Object count:</span><span>9876</span>"
      refute html =~ "Object count"
    end

    test "save_pipeline event correctly creates a new pipeline", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))
      render_click(view, :add_transform, %{})
      render_click(view, :add_transform, %{})
      render_click(view, :add_transform, %{})

      params = %{
        "name" => "My Pipeline",
        "transforms" => %{
          "0" => %{"driver" => "dicom_to_nifti", "order_index" => "0"},
          "1" => %{"driver" => "slicer", "order_index" => "1"},
          "2" => %{"driver" => "sample", "order_index" => "2"},
        }
      }
      render_change(view, :validate_pipeline, %{"pipeline" => params})
      send(view.pid, {:update_transform_options, {1, :slicer, %{"orientation" => "coronal"}}})
      send(view.pid, {:update_transform_options, {2, :sample, %{"object_count" => "99"}}})

      assert {:error, {:live_redirect, %{kind: :push, to: "/pipelines/1"}}} = render_change(view, :save_pipeline, %{"pipeline" => params})

      [%Pipeline{} = pipeline] = Assembly.list_pipelines_preloaded()
      assert pipeline.id == 1
      assert pipeline.name == "My Pipeline"

      [tr1, tr2, tr3] = pipeline.transforms
      assert %Transform{} = tr1
      assert tr1.driver == :dicom_to_nifti

      assert %Transform{} = tr2
      assert tr2.driver == :slicer
      assert tr2.options["orientation"] == "coronal"

      assert %Transform{} = tr3
      assert tr3.driver == :sample
      assert tr3.options["object_count"] == 99
    end


    test "add_transform event correctly adds transform", %{conn: conn} do
      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))

      refute html =~ "Step 1"
      refute html =~ "Step 2"

      html = render_click(view, :add_transform, %{})
      assert html =~ "Step 1"
      refute html =~ "Step 2"

      html = render_click(view, :add_transform, %{})
      assert html =~ "Step 1"
      assert html =~ "Step 2"
    end

    test "delete_transform event correctly deletes transform", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))
      render_click(view, :add_transform, %{})
      render_click(view, :add_transform, %{})
      render_click(view, :add_transform, %{})

      params = %{
        "name" => "",
        "transforms" => %{
          "0" => %{"driver" => "dicom_to_nifti", "order_index" => "0"},
          "1" => %{"driver" => "slicer", "order_index" => "1"},
          "2" => %{"driver" => "sample", "order_index" => "2"},
        }
      }
      html = render_change(view, :validate_pipeline, %{"pipeline" => params})

      assert html =~ "Step 1"
      assert html =~ "Step 2"
      assert html =~ "Step 3"

      assert html =~ ~s(<option selected="selected" value="dicom_to_nifti">)
      assert html =~ ~s(<option selected="selected" value="slicer">)
      assert html =~ ~s(<option selected="selected" value="sample">)

      html = render_click(view, :delete_transform, %{"index" => "1"})

      assert html =~ "Step 1"
      assert html =~ "Step 2"
      refute html =~ "Step 3"

      assert html =~ ~s(<option selected="selected" value="dicom_to_nifti">)
      refute html =~ ~s(<option selected="selected" value="slicer">)
      assert html =~ ~s(<option selected="selected" value="sample">)
    end

    test "edit_transform_options event correctly opens modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))
      html = render_click(view, :add_transform, %{})
      refute html =~ "<h3>Options for Step 1</h3>"

      html = render_click(view, :edit_transform_options, %{"index" => "0"})
      assert html =~ "<h3>Options for Step 1</h3>"
    end

    test "transform options modal correctly saves options", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))

      _html = render_click(view, :add_transform, %{})
      html = render_click(view, :edit_transform_options, %{"index" => "0"})

      refute html =~ "Object count:</span><span>9876</span>"

      view
      |> element("#transform-options-modal-form")
      |> render_submit(%{"options" => %{"object_count" => "9876"}})

      # We need to submit the form and then re-render afterwards
      # instead of directly receiving html from render_submit/2
      # because submitting the modal form sends a separate message
      # to the LiveView process telling it to close the modal,
      # and this is not reflected immediately in the html
      # received from render_submit/2
      html = render(view)
      assert html =~ "Object count:</span><span>9876</span>"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.New))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end

  describe "PipelineLive.Show" do
    test "renders pipeline with runs", %{conn: conn} do
      %Pipeline{} = pipeline = pipeline_fixture("My Pipeline")
      pipeline_run_fixture(pipeline, root_dataset_fixture("My First Dataset"))
      pipeline_run_fixture(pipeline, root_dataset_fixture("My Second Dataset"))
      pipeline_run_fixture(pipeline, root_dataset_fixture("My Third Dataset"))

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.Show, pipeline))
      assert html =~ "<h1>My Pipeline</h1>"

      assert html =~ "My First Dataset"
      assert html =~ "My Second Dataset"
      assert html =~ "My Third Dataset"
    end

    test "renders pipeline with no runs", %{conn: conn} do
      %Pipeline{} = pipeline = pipeline_fixture("My Pipeline")
      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.Show, pipeline))
      assert html =~ "<h1>My Pipeline</h1>"
    end

    test "renders steps when selected", %{conn: conn} do
      %Pipeline{} = pipeline = pipeline_fixture("My Pipeline")
      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.Show, pipeline))

      refute html =~ "slicer"
      refute html =~ "sample"

      html = render_click(view, "set_tab", %{"tab" => "steps"})
      assert html =~ "slicer"
      assert html =~ "sample"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      pipeline = pipeline_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineLive.Show, pipeline))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
