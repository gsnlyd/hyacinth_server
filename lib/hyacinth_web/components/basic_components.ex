defmodule HyacinthWeb.Components.BasicComponents do
  use Phoenix.Component
  import Phoenix.HTML.Form

  alias HyacinthWeb.Components.Icons
  alias Hyacinth.Assembly.Driver

  def modal(assigns) do
    assigns = assign_new(assigns, :close_event, fn -> "close_modal" end)
    assigns = assign_new(assigns, :size, fn -> "md" end)
    size_class =
      case assigns.size do
        "xs" -> "max-w-md"
        "sm" -> "max-w-screen-sm"
        "md" -> "max-w-screen-md"
        "lg" -> "max-w-screen-lg"
      end
    ~H"""
    <div class="top-0 left-0 fixed bg-black bg-opacity-90 flex justify-center items-start" style="width: 100vw; height: 100vh;">
      <div class={"flex-1 p-4 pt-2 #{size_class} bg-gray-800 rounded border border-gray-700"} style="margin-top: calc(2rem + 10vh);" phx-click-away={@close_event}>
        <div class="flex justify-between items-start">
          <h2><%= render_slot(@header) %></h2>
          <button class="-mt-2 text-3xl text-gray-500 hover:text-gray-300 transition" phx-click={@close_event}>&times;</button>
        </div>

        <div>
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  def tab_bar(assigns) do
    ~H"""
    <div class="mt-4 text-xl border-b-2 border-gray-700">
      <div class="-mb-0.5">
        <%= for tab <- @tab do %>
          <.tab_button cur_tab={@cur_tab} event={@event} tab={tab.name}>
            <%= render_slot(tab) %>
          </.tab_button>
        <% end %>
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
    <div class="pb-2 mb-2 text-sm border-b border-gray-700 flex items-center">
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

  def header_tag(assigns) do
    assigns = assign_new(assigns, :tooltip, fn -> nil end)
    ~H"""
    <div class="pl-1 pr-2 py-1 text-sm text-black font-medium bg-gray-300 rounded flex items-center" title={@tooltip}>
      <span class="opacity-80">
        <%= render_slot(@icon) %>
      </span>
      <span class="ml-1">
        <%= render_slot(@text) %>
      </span>
    </div>
    """
  end

  def link_card(assigns) do
    assigns =
      assigns
      |> assign_new(:tag, fn -> nil end)
      |> assign_new(:body, fn -> nil end)

    ~H"""
    <%= live_redirect to: @to, class: "block p-2 bg-gray-800 rounded border border-gray-700 hover:border-gray-500 transition" do %>
      <div class="flex justify-between items-start">
        <div class="shrink mt-0.5 text-sm text-gray-300 font-medium"><%= render_slot(@header) %></div>
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

  def driver_format_tags(assigns) do
    assigns = assign_new(assigns, :light, fn -> false end)
    assigns =
      if Driver.pure?(assigns.driver) do
        assign(assigns, %{
          input_format: :any,
          output_format: :any,
        })
      else
        assign(assigns, %{
          input_format: Driver.input_format(assigns.driver, assigns.options),
          output_format: Driver.output_format(assigns.driver, assigns.options),
        })
      end

    ~H"""
    <div class="flex items-center space-x-1">
      <span class={["tag", @light && "tag-light"]}><%= @input_format %></span>
      <span class="text-xs text-gray-400">&rarr;</span>
      <span class={["tag", @light && "tag-light"]}><%= @output_format %></span>
    </div>
    """
  end

  def options_table(assigns) do
    assigns = assign_new(assigns, :card, fn -> true end)
    ~H"""
    <div class={@card && "px-3 py-2 bg-gray-900 rounded"}>
      <table>
        <tbody class="text-sm text-gray-200">
          <%= for {k, v} <- @options do %>
            <tr>
              <td class={["pr-4", if(@card, do: "text-gray-500", else: "text-gray-400")]}><%= humanize(k) %></td>
              <td class="whitespace-pre"><%= if(is_list(v), do: Enum.join(v, ", "), else: v) %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @profile_image_colors [
    "bg-green-200 border-green-400",
    "bg-blue-200 border-blue-400",
    "bg-purple-200 border-purple-400",
    "bg-orange-200 border-orange-400",
    "bg-amber-200 border-amber-400",
    "bg-pink-200 border-pink-400",
  ]
  @num_profile_image_colors length(@profile_image_colors)

  def user_profile_image(assigns) do
    initials =
      assigns.user.name
      |> String.split()
      |> Enum.map(&String.first/1)
      |> Enum.join()

    color_i =
      assigns.user.name
      |> String.to_charlist()
      |> Enum.sum()
      |> rem(@num_profile_image_colors)

    assigns = assign(assigns, %{
      initials: initials,
      color_class: Enum.at(@profile_image_colors, color_i),
    })

    ~H"""
    <div class={["w-10 h-10 rounded-full border-2 flex justify-center items-center", @color_class]}>
      <span class="text-base text-black font-bold"><%= @initials %></span>
    </div>
    """
  end
end
