defmodule HyacinthWeb.ResultsLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.{AccountsFixtures, WarehouseFixtures, LabelingFixtures}

  alias Hyacinth.Labeling

  setup :register_and_log_in_user

  describe "ResultsLive.Show" do
    test "renders classification session results", %{conn: conn} do
      dataset = dataset_fixture(%{name: "My Dataset"}, many_object_params_fixtures(4, "my_object", :png))
      job = label_job_fixture(%{name: "My Job", type: :classification, label_options_string: "First Option, Second Option, Third Option"}, dataset)
      user = user_fixture(%{name: "My User"})
      label_session = label_session_fixture(job, user)

      [el1, el2, el3, el4] = Labeling.get_label_session_with_elements!(label_session.id).elements
      Labeling.create_label_entry!(el1, user, "First Option", DateTime.utc_now())
      Labeling.create_label_entry!(el1, user, "Second Option", DateTime.utc_now())
      Labeling.create_label_entry!(el2, user, "Third Option", DateTime.utc_now())
      Labeling.create_label_entry!(el3, user, "First Option", DateTime.utc_now())
      Labeling.create_label_entry!(el4, user, "Second Option", DateTime.utc_now())

      {:ok, _view, html} = live(conn, Routes.results_show_path(conn, :show_session, label_session))

      assert html =~ "My User"
      assert html =~ "First Option"
      assert html =~ "Second Option"
      assert html =~ "Third Option"

      assert html =~ "my_object1.png"
      assert html =~ "my_object2.png"
      assert html =~ "my_object3.png"
      assert html =~ "my_object4.png"
    end

    test "renders classification job results", %{conn: conn} do
      dataset = dataset_fixture(%{name: "My Dataset"}, many_object_params_fixtures(4, "my_object", :png))
      job = label_job_fixture(%{name: "My Job", type: :classification, label_options_string: "First Option, Second Option, Third Option"}, dataset)
      user = user_fixture(%{name: "My User"})

      label_session1 = label_session_fixture(job, user)
      label_session2 = label_session_fixture(job, user)

      [s1el1, s1el2, s1el3, s1el4] = Labeling.get_label_session_with_elements!(label_session1.id).elements
      Labeling.create_label_entry!(s1el1, user, "First Option", DateTime.utc_now())
      Labeling.create_label_entry!(s1el1, user, "Second Option", DateTime.utc_now())
      Labeling.create_label_entry!(s1el2, user, "Third Option", DateTime.utc_now())
      Labeling.create_label_entry!(s1el3, user, "First Option", DateTime.utc_now())
      Labeling.create_label_entry!(s1el4, user, "Second Option", DateTime.utc_now())

      [s2el1, s2el2, s2el3, s2el4] = Labeling.get_label_session_with_elements!(label_session2.id).elements
      Labeling.create_label_entry!(s2el4, user, "First Option", DateTime.utc_now())
      Labeling.create_label_entry!(s2el3, user, "Second Option", DateTime.utc_now())
      Labeling.create_label_entry!(s2el2, user, "Third Option", DateTime.utc_now())
      Labeling.create_label_entry!(s2el1, user, "First Option", DateTime.utc_now())
      Labeling.create_label_entry!(s2el1, user, "Second Option", DateTime.utc_now())

      {:ok, _view, html} = live(conn, Routes.results_show_path(conn, :show_job, job))

      assert html =~ "My Job"
      assert html =~ "First Option"
      assert html =~ "Second Option"
      assert html =~ "Third Option"

      assert html =~ "my_object1.png"
      assert html =~ "my_object2.png"
      assert html =~ "my_object3.png"
      assert html =~ "my_object4.png"
    end

    @tag :disable_login
    test "show_session fails if user is not logged in", %{conn: conn} do
      label_session = label_session_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.results_show_path(conn, :show_session, label_session))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end

    @tag :disable_login
    test "show_job fails if user is not logged in", %{conn: conn} do
      job = label_job_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.results_show_path(conn, :show_job, job))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
