defmodule HyacinthWeb.ImageController do
  use HyacinthWeb, :controller

  alias Hyacinth.Warehouse
  alias Hyacinth.Warehouse.Object

  def show(conn, %{"object_id" => object_id}) do
    %Object{} = object = Warehouse.get_object!(object_id)
    if object.type != :blob, do: raise "Only blobs can be served"
    if object.format != :png, do: raise "Only pngs can be served"

    path = Warehouse.Store.get_object_path_from_hash(object.hash)
    Phoenix.Controller.send_download(conn, {:file, path}, content_type: "image/png", disposition: :inline)
  end
end
