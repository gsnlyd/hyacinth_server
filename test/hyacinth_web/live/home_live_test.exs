defmodule HyacinthWeb.HomeLiveTest do
  use HyacinthWeb.ConnCase

  setup :register_and_log_in_user

  describe "HomeLive.Index" do
    test "renders page", %{conn: conn} do
      {:ok, _view, _html} = live(conn, Routes.live_path(conn, HyacinthWeb.HomeLive.Index))
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.HomeLive.Index))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
