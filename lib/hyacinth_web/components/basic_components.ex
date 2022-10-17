defmodule HyacinthWeb.Components.BasicComponents do
  use Phoenix.Component
  alias HyacinthWeb.Components.Icons

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
end
