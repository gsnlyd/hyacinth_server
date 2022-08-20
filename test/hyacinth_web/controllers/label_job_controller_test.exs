defmodule HyacinthWeb.LabelJobControllerTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.WarehouseFixtures
  import Hyacinth.LabelingFixtures

  @create_attrs %{name: "some name", label_type: :classification, label_options_string: "option 1, option 2, option 3"}
  @invalid_attrs %{label_type: nil, name: nil, dataset_id: nil}

  describe "index" do
    test "lists all label_jobs", %{conn: conn} do
      conn = get(conn, Routes.label_job_path(conn, :index))
      assert html_response(conn, 200) =~ "Label Jobs"
    end
  end

  describe "new label_job" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.label_job_path(conn, :new))
      assert html_response(conn, 200) =~ "New Label job"
    end
  end

  describe "create label_job" do
    setup [:register_and_log_in_user]

    test "redirects to show when data is valid", %{conn: conn} do
      dataset = root_dataset_fixture()
      attrs = Map.put(@create_attrs, :dataset_id, dataset.id)
      conn = post(conn, Routes.label_job_path(conn, :create), label_job: attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.label_job_path(conn, :show, id)

      conn = get(conn, Routes.label_job_path(conn, :show, id))
      assert html_response(conn, 200) =~ "some name</h1>"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.label_job_path(conn, :create), label_job: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Label job"
    end
  end

  describe "edit label_job" do
    setup [:create_label_job]

    test "renders form for editing chosen label_job", %{conn: conn, label_job: label_job} do
      conn = get(conn, Routes.label_job_path(conn, :edit, label_job))
      assert html_response(conn, 200) =~ "Edit Label job"
    end
  end

  defp create_label_job(_) do
    label_job = label_job_fixture()
    %{label_job: label_job}
  end
end
