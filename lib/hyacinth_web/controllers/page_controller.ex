defmodule HyacinthWeb.PageController do
  use HyacinthWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
