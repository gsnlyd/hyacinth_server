defmodule HyacinthWeb.Components.BasicComponents do
  use Phoenix.Component

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
end
