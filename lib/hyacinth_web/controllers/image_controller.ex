defmodule HyacinthWeb.ImageController do
  use HyacinthWeb, :controller

  alias Hyacinth.Warehouse

  def show(conn, %{"element_id" => element_id}) do
    element = Warehouse.get_element!(element_id)

    if Path.extname(element.path) != ".png", do: raise "invalid element path"  # TODO: sanity, remove later
    Plug.Conn.send_file(conn, 200, element.path)
  end
end
