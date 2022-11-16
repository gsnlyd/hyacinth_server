defmodule HyacinthWeb.PipelineLive.TransformOptionsModal do
  use HyacinthWeb, :live_component

  alias Hyacinth.Assembly.Driver

  def update(assigns, socket) do
    socket = assign(socket, %{
      index: assigns.index,
      driver: assigns.driver,
      changeset: Driver.options_changeset(assigns.driver, assigns.options_params),
    })
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="top-0 left-0 fixed bg-black bg-opacity-90 flex justify-center items-start" style="width: 100vw; height: 100vh;">
      <div class="flex-1 mt-64 p-4 max-w-lg bg-gray-800 rounded border border-gray-700" phx-click-away="close_modal">
        <div>
          <h3>Options for Step <%= @index + 1 %></h3>
        </div>
        <div class="mt-4">
          <.form let={f} for={@changeset} as="options" phx-change="validate_change" phx-submit="validate_submit" phx-target={@myself} id="transform-options-modal-form">
            <Driver.render_form driver={@driver} form={f} />
            <div class="mt-6">
              <%= submit "Save", class: "btn btn-blue" %>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("validate_change", %{"options" => params}, socket) do
    changeset =
      socket.assigns.driver
      |> Driver.options_changeset(params)
      |> Map.put(:action, :insert)
    socket = assign(socket, :changeset, changeset)
    {:noreply, socket}
  end

  def handle_event("validate_submit", %{"options" => params}, socket) do
    changeset = Driver.options_changeset(socket.assigns.driver, params)
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, schema} ->
        schema_params = Map.from_struct(schema)
        message = {socket.assigns.index, socket.assigns.driver, schema_params}
        send self(), {:update_transform_options, message}

        socket

      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, :changeset, changeset)
    end
    {:noreply, socket}
  end
end
