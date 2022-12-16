defmodule HyacinthWeb.ViewerLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Warehouse

  defmodule ViewerSelectForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :viewer, Ecto.Enum, values: [:web_image, :advanced_png], default: :web_image
    end

    @doc false
    def changeset(viewer_select_form, attrs) do
      viewer_select_form
      |> cast(attrs, [:viewer])
      |> validate_required([:viewer])
    end
  end


  def mount(params, _session, socket) do
    object = Warehouse.get_object!(params["object_id"])
    socket = assign(socket, %{
      object: object,
      viewer_select_changeset: ViewerSelectForm.changeset(%ViewerSelectForm{}, %{}),

      import_viewer_scripts: true,
    })
    {:ok, socket}
  end

  def handle_event("form_change", %{"viewer_select_form" => params}, socket) do
    changeset = ViewerSelectForm.changeset(%ViewerSelectForm{}, params)
    socket = assign(socket, %{
      viewer_select_changeset: changeset,
    })
    {:noreply, socket}
  end
end
