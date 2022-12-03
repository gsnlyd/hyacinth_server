defmodule HyacinthWeb.Components.BasicComponents do
  use Phoenix.Component
  alias HyacinthWeb.Components.Icons

  def modal(assigns) do
    assigns = assign_new(assigns, :close_event, fn -> "close_modal" end)
    assigns = assign_new(assigns, :size, fn -> "md" end)
    size_class =
      case assigns.size do
        "sm" -> "max-w-screen-sm"
        "md" -> "max-w-screen-md"
        "lg" -> "max-w-screen-lg"
      end
    ~H"""
    <div class="top-0 left-0 fixed bg-black bg-opacity-90 flex justify-center items-start" style="width: 100vw; height: 100vh;">
      <div class={"flex-1 mt-20 p-4 pt-2 #{size_class} bg-gray-800 rounded border border-gray-700"} phx-click-away={@close_event}>
        <div class="flex justify-between items-start">
          <h1><%= render_slot(@header) %></h1>
          <button class="-mt-2 text-4xl text-gray-500 hover:text-gray-300 transition" phx-click={@close_event}>&times;</button>
        </div>

        <div>
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  def tab_button(assigns) do
    button_class =
      "px-2 pb-1 border-purple-400 transition" <>
        if Atom.to_string(assigns.cur_tab) == assigns.tab do
          "text-white border-b-2"
        else
          "px-1 text-gray-400 hover:text-white"
        end
    assigns = assign(assigns, :button_class, button_class)

    ~H"""
    <button class={@button_class} phx-click={@event} phx-value-tab={@tab}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def breadcrumbs(assigns) do
    ~H"""
    <div class="text-sm flex items-center">
      <%= for {crumb, i} <- Enum.with_index(@crumb) do %>
        <%= if i > 0 do %>
          <span class="text-gray-500">
            <Icons.chevron_right_mini />
          </span>
        <% end %>

        <%= if crumb.label do %>
          <span class="px-1 py-0.5 mr-1 text-xs text-gray-400 bg-gray-800 rounded"><%= crumb.label %></span>
        <% end %>

        <%= live_redirect to: crumb.to, class: "link" do %>
          <%= render_slot(crumb) %>
        <% end %>
      <% end %>
    </div>
    """
  end

  def link_card(assigns) do
    assigns =
      assigns
      |> assign_new(:tag, fn -> nil end)
      |> assign_new(:body, fn -> nil end)

    ~H"""
    <%= live_redirect to: @to, class: "p-2 bg-gray-800 rounded border border-gray-700 hover:border-gray-500 transition" do %>
      <div class="flex justify-between items-start">
        <div class="shrink text-sm text-gray-300 font-medium"><%= render_slot(@header) %></div>
        <%= if @tag do %>
          <div class="shrink-0 ml-4">
            <%= render_slot(@tag) %>
          </div>
        <% end %>
      </div>

      <div>
        <%= if @body do %>
          <%= render_slot(@body) %>
        <% end %>
      </div>

      <div class="mt-2 text-xs text-gray-500"><%= render_slot(@footer) %></div>
    <% end %>
    """
  end
end
