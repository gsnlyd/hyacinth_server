defmodule HyacinthWeb.LabelSessionLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.{AccountsFixtures, WarehouseFixtures, LabelingFixtures}

  alias Hyacinth.Labeling
  alias Hyacinth.Labeling.{LabelSession, LabelElement, LabelEntry}

  setup :register_and_log_in_user

  describe "LabelSessionLive.Show" do
    test "renders label session", %{conn: conn} do
      dataset = root_dataset_fixture("My Dataset", 3, "My Object No")
      job = label_job_fixture(%{name: "My Job", labeling_options_string: "option 1, option 2, option 3"}, dataset)
      user = user_fixture(%{email: "someuser@example.com"})
      %LabelSession{} = label_session = label_session_fixture(job, user)

      [e1, e2, _e3] = Labeling.get_label_session_with_elements!(label_session.id).elements
      Labeling.create_label_entry!(e1, user, "option 1")
      Labeling.create_label_entry!(e2, user, "option 2")
      Labeling.create_label_entry!(e2, user, "option 3")  # Overwrite previous label

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Show, label_session))
      assert html =~ "My Job"
      assert html =~ "My Dataset"
      assert html =~ "someuser@example.com"

      assert html =~ "My Object No1"
      assert html =~ "My Object No2"
      assert html =~ "My Object No3"

      assert html =~ "option 1</td>"
      refute html =~ "option 2</td>"
      assert html =~ "option 3</td>"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      %LabelSession{} = label_session = label_session_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Show, label_session))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end

  describe "LabelSessionLive.Label" do
    test "renders labeling interface", %{conn: conn} do
      dataset = root_dataset_fixture("My Dataset", 3, "My Object No")
      job = label_job_fixture(%{name: "My Job", label_options_string: "First Option, Second Option, Third Option"}, dataset)
      %LabelSession{} = label_session = label_session_fixture(job)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 0))
      assert html =~ "My Object No"

      assert html =~ "First Option"
      assert html =~ "Second Option"
      assert html =~ "Third Option"
    end

    test "set_label event correctly adds a label entry", %{conn: conn, user: user} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job, user)

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 0))
      refute html =~ "btn-dark-blue"

      html = render_click(view, :set_label, %{"label" => "First Option"})
      assert html =~ "btn-dark-blue"

      %LabelElement{} = element = Labeling.get_label_element!(label_session, 0)
      assert [%LabelEntry{value: %LabelEntry.Value{option: "First Option"}}] = Labeling.list_element_labels(element)
    end

    test "set_label_key event correctly adds a label entry", %{conn: conn, user: user} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job, user)

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 0))
      refute html =~ "btn-dark-blue"

      html = render_keydown(view, :set_label_key, %{"key" => "1"})
      assert html =~ "btn-dark-blue"

      %LabelElement{} = element = Labeling.get_label_element!(label_session, 0)
      assert [%LabelEntry{value: %LabelEntry.Value{option: "First Option"}}] = Labeling.list_element_labels(element)
    end

    test "prev_element event redirects", %{conn: conn} do
      %LabelSession{} = label_session = label_session_fixture()
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))

      assert {:error, {:live_redirect, %{kind: :push, to: "/sessions/2/label/0"}}} = render_click(view, :prev_element, %{})
    end

    test "next_element event redirects", %{conn: conn} do
      %LabelSession{} = label_session = label_session_fixture()
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))

      assert {:error, {:live_redirect, %{kind: :push, to: "/sessions/2/label/2"}}} = render_click(view, :next_element, %{})
    end

    test "open_modal_label_history event opens label history modal", %{conn: conn} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job)

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))
      refute html =~ "<h1>Label History</h1>"

      html = render_click(view, :open_modal_label_history, %{})
      assert html =~ "<h1>Label History</h1>"
    end

    test "open_modal_notes event opens notes modal", %{conn: conn} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job)

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))
      refute html =~ "<h1>Notes</h1>"

      html = render_click(view, :open_modal_notes, %{})
      assert html =~ "<h1>Notes</h1>"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      %LabelSession{} = label_session = label_session_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 0))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
