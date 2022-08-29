defmodule HyacinthWeb.ImageController do
  use HyacinthWeb, :controller

  alias Hyacinth.Warehouse

  def show(conn, %{"object_id" => object_id}) do
    object = Warehouse.get_object!(object_id)

    path = Warehouse.Store.get_object_path_from_hash(object.hash)
    Phoenix.Controller.send_download(conn, {:file, path}, content_type: "image/png", disposition: :inline)
  end
end
