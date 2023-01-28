defmodule HyacinthWeb.UserLiveTest do
  use HyacinthWeb.ConnCase

  import Hyacinth.AccountsFixtures

  setup :register_and_log_in_user

  describe "UserLive.Index" do
    test "renders users", %{conn: conn} do
      user_fixture(%{name: "First User"})
      user_fixture(%{name: "Second User"})
      user_fixture(%{name: "Third User"})

      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.UserLive.Index))

      assert html =~ "First User"
      assert html =~ "Second User"
      assert html =~ "Third User"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.UserLive.Index))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end

  describe "UserLive.Show" do
    test "renders page", %{conn: conn} do
      user = user_fixture(%{name: "My User"})
      {:ok, _view, html} = live(conn, Routes.live_path(conn, HyacinthWeb.UserLive.Show, user))

      assert html =~ "My User"
    end

    @tag :disable_login
    test "fails if user is not logged in", %{conn: conn} do
      user = user_fixture()
      {:error, {:redirect, redirect_params}} = live(conn, Routes.live_path(conn, HyacinthWeb.UserLive.Show, user))
      assert %{flash: %{"error" => "You must log in to access this page."}} = redirect_params
    end
  end
end
