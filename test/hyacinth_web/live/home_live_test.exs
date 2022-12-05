defmodule HyacinthWeb.HomeLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.{WarehouseFixtures, AssemblyFixtures, LabelingFixtures}

  setup :register_and_log_in_user

  describe "HomeLive.Index" do
    test "renders page", %{conn: conn, user: user} do
      root_dataset_fixture("My First Dataset")
      root_dataset_fixture("My Second Dataset")

      pipeline_fixture("My First Pipeline")
      pipeline_fixture("My Second Pipeline")

      job1 = label_job_fixture(%{name: "My First Label Job"})
      job2 = label_job_fixture(%{name: "My Second Label Job"})

      label_session_fixture(job1, user)
      label_session_fixture(job2, user)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.HomeLive.Index))

      assert html =~ "My First Dataset"
      assert html =~ "My Second Dataset"

      assert html =~ "My First Pipeline"
      assert html =~ "My Second Pipeline"

      assert html =~ "My First Label Job"
      assert html =~ "My Second Label Job"
    end

    test "renders with no data", %{conn: conn} do
      {:ok, _view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.HomeLive.Index))
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.HomeLive.Index))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
