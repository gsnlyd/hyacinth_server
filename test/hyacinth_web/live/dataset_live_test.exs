defmodule HyacinthWeb.DatasetLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.{WarehouseFixtures, LabelingFixtures}

  alias Hyacinth.Warehouse.Dataset

  setup :register_and_log_in_user

  describe "DatasetLive.Index" do
    test "renders datasets", %{conn: conn} do
      root_dataset_fixture("My First Dataset")
      root_dataset_fixture("My Second Dataset")
      root_dataset_fixture("My Third Dataset")

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.DatasetLive.Index))
      assert html =~ "<h1>Datasets</h1>"

      assert html =~ "My First Dataset"
      assert html =~ "My Second Dataset"
      assert html =~ "My Third Dataset"
    end

    test "renders with no datasets", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.DatasetLive.Index))
      assert html =~ "<h1>Datasets</h1>"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.DatasetLive.Index))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end

  describe "DatasetLive.Show" do
    test "renders dataset with jobs", %{conn: conn} do
      %Dataset{} = dataset = root_dataset_fixture("My Dataset")
      label_job_fixture(%{name: "My First Job"}, dataset)
      label_job_fixture(%{name: "My Second Job"}, dataset)
      label_job_fixture(%{name: "My Third Job"}, dataset)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.DatasetLive.Show, dataset))
      assert html =~ "<h1>My Dataset</h1>"

      assert html =~ "My First Job"
      assert html =~ "My Second Job"
      assert html =~ "My Third Job"
    end

    test "renders dataset with no jobs", %{conn: conn} do
      %Dataset{} = dataset = root_dataset_fixture("My Dataset")

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.DatasetLive.Show, dataset))
      assert html =~ "<h1>My Dataset</h1>"
    end

    test "renders objects tab when selected", %{conn: conn} do
      %Dataset{} = dataset = root_dataset_fixture("My Dataset", 3, "My Object No")

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.DatasetLive.Show, dataset))
      assert html =~ "<h1>My Dataset</h1>"
      refute html =~ "My Object No1"

      html = render_click(view, "set_tab", %{"tab" => "objects"})
      assert html =~ "My Object No1"
      assert html =~ "My Object No2"
      assert html =~ "My Object No3"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      %Dataset{} = dataset = root_dataset_fixture("My Dataset")
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.DatasetLive.Show, dataset))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
