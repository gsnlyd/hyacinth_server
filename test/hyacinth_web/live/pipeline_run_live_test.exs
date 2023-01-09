defmodule HyacinthWeb.PipelineRunLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.{WarehouseFixtures, AssemblyFixtures, AccountsFixtures}

  alias Hyacinth.Assembly.PipelineRun

  setup :register_and_log_in_user

  describe "PipelineRunLive.Show" do
    test "renders pipeline run", %{conn: conn} do
      pipeline = pipeline_fixture("My Pipeline")
      dataset = root_dataset_fixture("My Dataset")
      user = user_fixture(%{name: "Some User", email: "someuser@example.com"})
      %PipelineRun{} = pipeline_run = pipeline_run_fixture(pipeline, dataset, user)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineRunLive.Show, pipeline_run))

      assert html =~ "My Pipeline"
      assert html =~ "My Dataset"
      assert html =~ "Some User"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      %PipelineRun{} = pipeline_run = pipeline_run_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.PipelineRunLive.Show, pipeline_run))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
