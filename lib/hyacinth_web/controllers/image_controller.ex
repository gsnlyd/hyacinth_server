defmodule HyacinthWeb.ImageController do
  use HyacinthWeb, :controller

  alias Hyacinth.Warehouse

  def show(conn, %{"object_id" => object_id}) do
    object = Warehouse.get_object!(object_id)

    if Path.extname(object.path) != ".png", do: raise "invalid object path"  # TODO: sanity, remove later
    Plug.Conn.send_file(conn, 200, object.path)
  end
end
