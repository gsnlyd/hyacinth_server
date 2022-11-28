defmodule HyacinthWeb.LabelJobLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.{AccountsFixtures, WarehouseFixtures, LabelingFixtures}

  alias Hyacinth.Labeling
  alias Hyacinth.Labeling.LabelJob

  setup :register_and_log_in_user

  describe "LabelJobLive.New" do
    test "renders page", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.New))
      assert html =~ "<h1>New Job</h1>"
    end

    test "renders page with correct dataset options", %{conn: conn} do
      root_dataset_fixture("My First Dataset")
      root_dataset_fixture("My Second Dataset")
      root_dataset_fixture("My Third Dataset")

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.New))
      assert html =~ "<h1>New Job</h1>"

      assert html =~ "My First Dataset</option>"
      assert html =~ "My Second Dataset</option>"
      assert html =~ "My Third Dataset</option>"
    end

    test "form_change event updates page", %{conn: conn} do
      root_dataset_fixture("My Dataset")
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.New))

      params = %{
        "dataset_id" => "1",
        "name" => "My New Job",
        "type" => "classification",
        "label_options_string" => "Label 1, Label 2, Label 3",
      }

      html = render_change(view, :form_change, %{"label_job" => params})

      assert html =~ ~s(<option selected="selected" value="1">)
      assert html =~ "My New Job"
      assert html =~ ~s(<option selected="selected" value="classification">)
      assert html =~ "Label 1, Label 2, Label 3"
    end

    test "form_submit event creates job", %{conn: conn} do
      root_dataset_fixture("My Dataset")
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.New))

      params = %{
        "dataset_id" => "1",
        "name" => "My New Job",
        "type" => "classification",
        "label_options_string" => "Label 1, Label 2, Label 3",
      }
      assert {:error, {:live_redirect, %{kind: :push, to: "/jobs/1"}}} = render_change(view, :form_submit, %{"label_job" => params})

      [%LabelJob{} = job] = Labeling.list_label_jobs()
      assert job.name == "My New Job"
      assert job.type == :classification
      assert job.label_options == ["Label 1", "Label 2", "Label 3"]
      assert job.dataset_id == 1
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.New))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end

  describe "LabelJobLive.Show" do
    test "renders job with sessions", %{conn: conn} do
      %LabelJob{} = job = label_job_fixture(%{name: "My Job"})
      label_session_fixture(job, user_fixture(%{email: "firstuser@example.com"}))
      label_session_fixture(job, user_fixture(%{email: "seconduser@example.com"}))
      label_session_fixture(job, user_fixture(%{email: "thirduser@example.com"}))

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.Show, job))
      assert html =~ "<h1>My Job</h1>"

      assert html =~ "firstuser@example.com"
      assert html =~ "seconduser@example.com"
      assert html =~ "thirduser@example.com"
    end

    test "renders job with no sessions", %{conn: conn} do
      %LabelJob{} = job = label_job_fixture(%{name: "My Job"})
      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.Show, job))
      assert html =~ "<h1>My Job</h1>"
    end

    test "renders elements tab when selected", %{conn: conn} do
      dataset = root_dataset_fixture("My Dataset", 3, "My Object No")
      %LabelJob{} = job = label_job_fixture(%{name: "My Job"}, dataset)

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.Show, job))
      refute html =~ "My Object No1"

      html = render_click(view, :set_tab, %{"tab" => "elements"})
      assert html =~ "My Object No1"
      assert html =~ "My Object No2"
      assert html =~ "My Object No3"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      %LabelJob{} = job = label_job_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelJobLive.Show, job))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
