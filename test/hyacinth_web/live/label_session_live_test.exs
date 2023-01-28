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
      user = user_fixture(%{name: "Some User", email: "someuser@example.com"})
      %LabelSession{} = label_session = label_session_fixture(job, user)

      [e1, e2, _e3] = Labeling.get_label_session_with_elements!(label_session.id).elements
      Labeling.create_label_entry!(e1, user, "option 1", DateTime.utc_now())
      Labeling.create_label_entry!(e2, user, "option 2", DateTime.utc_now())
      Labeling.create_label_entry!(e2, user, "option 3", DateTime.utc_now())  # Overwrite previous label

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Show, label_session))
      assert html =~ "My Job"
      assert html =~ "My Dataset"
      assert html =~ "Some User"

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

      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 0))

      _html = render_click(view, :set_label, %{"label" => "First Option"})

      %LabelElement{} = element = Labeling.get_label_element!(label_session, 0)
      assert [%LabelEntry{value: %LabelEntry.Value{option: "First Option"}}] = Labeling.list_element_labels(element)
    end

    test "set_label_key event correctly adds a label entry", %{conn: conn, user: user} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job, user)

      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 0))

      _html = render_keydown(view, :set_label_key, %{"key" => "1"})

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

    test "open_modal_label_history event opens label history modal with empty history", %{conn: conn} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job)

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))
      refute html =~ "<h2>Label History</h2>"

      html = render_click(view, :open_modal_label_history, %{})
      assert html =~ "<h2>Label History</h2>"
      assert html =~ "No label history yet."
    end

    test "open_modal_label_history event opens label history modal with history", %{conn: conn, user: user} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job, user)

      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))
      render_click(view, :set_label, %{"label" => "First Option"})
      render_click(view, :set_label, %{"label" => "Second Option"})
      html = render_click(view, :set_label, %{"label" => "First Option"})

      refute html =~ "<h2>Label History</h2>"

      html = render_click(view, :open_modal_label_history, %{})
      assert html =~ "<h2>Label History</h2>"
      assert html =~ "First Option</td>"
      assert html =~ "Second Option</td>"
      refute html =~ "Third Option</td>"
    end

    test "open_modal_notes event opens notes modal", %{conn: conn} do
      job = label_job_fixture(%{label_options_string: "First Option, Second Option, Third Option"})
      %LabelSession{} = label_session = label_session_fixture(job)

      {:ok, view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))
      refute html =~ "<h2>Notes</h2>"

      html = render_click(view, :open_modal_notes, %{})
      assert html =~ "<h2>Notes</h2>"
    end

    test "note_submit event creates note", %{conn: conn, user: user} do
      %LabelSession{} = label_session = label_session_fixture(nil, user)
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))

      html = render_click(view, :open_modal_notes, %{})
      assert html =~ "<h2>Notes</h2>"
      refute html =~ "These are my notes."

      params = %{"text" => "These are my notes."}
      render_submit(view, :note_submit, %{"note" => params})

      html = render_click(view, :open_modal_notes, %{})
      assert html =~ "<h2>Notes</h2>"
      assert html =~ "These are my notes."
    end

    test "note_submit event updates note", %{conn: conn, user: user} do
      %LabelSession{} = label_session = label_session_fixture(nil, user)
      {:ok, view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 1))

      render_click(view, :open_modal_notes, %{})

      params = %{"text" => "These are my initial notes."}
      render_submit(view, :note_submit, %{"note" => params})

      html = render_click(view, :open_modal_notes, %{})
      assert html =~ "<h2>Notes</h2>"
      assert html =~ "These are my initial notes."

      params = %{"text" => "These are my updated notes."}
      render_submit(view, :note_submit, %{"note" => params})

      html = render_click(view, :open_modal_notes, %{})
      assert html =~ "<h2>Notes</h2>"
      refute html =~ "These are my initial notes."
      assert html =~ "These are my updated notes."
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      %LabelSession{} = label_session = label_session_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.LabelSessionLive.Label, label_session, 0))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
