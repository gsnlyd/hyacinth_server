defmodule HyacinthWeb.PipelineLive.New do
  use HyacinthWeb, :live_view

  alias Hyacinth.Assembly
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      pipeline_changeset: Pipeline.changeset(%Pipeline{}, %{}),
      transform_options: [],
      transforms: [],

      modal: nil,
    })

    {:ok, socket}
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

  @spec inject_options(%{String.t => term}, [{atom, map}]) :: {%{String.t => term}, [{atom, map}]}
  defp inject_options(transforms_params, options_params) do
    # This function injects options params into transform params
    # and also replaces any options params that have a mismatched driver
    # with defaults if the driver has been changed by the user

    # Transform params are nil if there are no transforms yet
    transforms_params = transforms_params || []

    # The form returns the assoc params in a map,
    # so we have to sort by order_index to guarantee
    # order before zipping with the options list
    transforms_sorted =
      transforms_params
      |> Enum.map(fn {k, v} -> {k, v} end)
      |> Enum.sort_by(fn {_k, v} -> String.to_integer(v["order_index"]) end)

    # We zip the transform params and options params together
    # so that we can manipulate both lists at once.
    # Then, we either inject the options into the transform params,
    # or, if there is a driver mismatch, we reset the options
    # in both lists to the driver default.
    {transforms_list, options_list} =
      Enum.zip(transforms_sorted, options_params)
      |> Enum.map(fn {{tid, tparams}, {opts_driver, opts}} ->
        params_driver = Driver.from_string!(tparams["driver"])
        if params_driver == opts_driver do
          tparams = Map.put(tparams, "options", opts)
          {{tid, tparams}, {opts_driver, opts}}
        else
          new_opts =
            params_driver
            |> Driver.options_changeset(%{})
            |> Ecto.Changeset.apply_action!(:insert)
            |> Map.from_struct()
          tparams = Map.put(tparams, "options", new_opts)
          {{tid, tparams}, {params_driver, new_opts}}
        end
      end)
      |> Enum.unzip()

    transforms_map = Map.new(transforms_list)
    {transforms_map, options_list}
  end

  @spec convert_transform_list_to_params([{atom, map}]) :: [map]
  defp convert_transform_list_to_params(transforms) when is_list(transforms) do
    transforms
    |> Enum.with_index()
    |> Enum.map(fn {{driver, options}, order_index} ->
      %{order_index: order_index, driver: driver, options: options}
    end)
  end

  def handle_event("validate_pipeline", %{"pipeline" => pipeline_params}, socket) do
    {new_transforms, new_options} = inject_options(pipeline_params["transforms"], socket.assigns.transform_options)
    pipeline_params = Map.put(pipeline_params, "transforms", new_transforms)

    pipeline_changeset =
      %Pipeline{}
      |> Pipeline.changeset(pipeline_params)
      |> Map.put(:action, :insert)

    socket = assign(socket, %{
      pipeline_changeset: pipeline_changeset,
      transform_options: new_options,
    })
    {:noreply, socket}
  end

  def handle_event("save_pipeline", %{"pipeline" => pipeline_params}, socket) do
    {new_transforms, new_options} = inject_options(pipeline_params["transforms"], socket.assigns.transform_options)
    pipeline_params = Map.put(pipeline_params, "transforms", new_transforms)

    case Assembly.create_pipeline(socket.assigns.current_user, pipeline_params) do
      {:ok, %Pipeline{} = pipeline} ->
        {:noreply, push_redirect(socket, to: Routes.live_path(socket, HyacinthWeb.PipelineLive.Show, pipeline.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, %{
          pipeline_changeset: changeset,
          transform_options: new_options,
        })
        {:noreply, socket}

    end
  end

  def handle_event("add_transform", _value, socket) do
    # Get default options as a map of params
    default_driver = :sample
    default_options =
      default_driver
      |> Driver.options_changeset(%{})
      |> Ecto.Changeset.apply_action!(:insert)
      |> Map.from_struct()

    # Add new transform to list of transforms and convert to params to cast into the changeset
    transform_options = socket.assigns.transform_options ++ [{default_driver, default_options}]
    transforms_params = convert_transform_list_to_params(transform_options)

    # Rebuild changeset with new transforms params
    # Note: it is necessary to rebuild instead of calling changeset(existing_changeset, additional_params)
    # because re-running the validations does not remove existing errors, causing ghost
    # errors to persist on the :transforms field
    pipeline_params = Map.put(socket.assigns.pipeline_changeset.params, "transforms", transforms_params)
    pipeline_changeset =
      %Pipeline{}
      |> Pipeline.changeset(pipeline_params)
      |> Map.put(:action, :insert)

    # Update state
    socket = assign(socket, %{
      pipeline_changeset: pipeline_changeset,
      transform_options: transform_options,
    })

    {:noreply, socket}
  end

  def handle_event("delete_transform", %{"index" => index}, socket) do
    index = String.to_integer(index)

    # Delete transform from list of transforms and convert to params to cast into the changeset
    transform_options = List.delete_at(socket.assigns.transform_options, index)
    transforms_params = convert_transform_list_to_params(transform_options)

    # Rebuild changeset with new transforms params (see note in add_transform above)
    pipeline_params = Map.put(socket.assigns.pipeline_changeset.params, "transforms", transforms_params)
    pipeline_changeset =
      %Pipeline{}
      |> Pipeline.changeset(pipeline_params)
      |> Map.put(:action, :insert)

    socket = assign(socket, %{
      pipeline_changeset: pipeline_changeset,
      transform_options: transform_options,
    })
    {:noreply, socket}
  end

  def handle_event("edit_transform_options", %{"index" => index}, socket) do
    index = String.to_integer(index)
    {driver, options_params} = Enum.at(socket.assigns.transform_options, index)
    socket = assign(socket, :modal, {:transform_options, {index, driver, options_params}})
    {:noreply, socket}
  end

  def handle_event("close_modal", _value, socket) do
    {:noreply, assign(socket, :modal, nil)}
  end

  def handle_info({:update_transform_options, {index, driver, params}}, socket) do
    transform_options = socket.assigns.transform_options

    # Sanity check
    {cur_driver, _opts} = Enum.at(transform_options, index)
    if cur_driver != driver, do: raise "Driver mismatch: expected #{cur_driver} got #{driver}"

    # Replace existing options with new options and convert to params to cast into the changeset
    transform_options = List.replace_at(transform_options, index, {driver, params})
    transforms_params = convert_transform_list_to_params(transform_options)
    
    # Rebuild changeset with new transforms params (see note in add_transform above)
    pipeline_params = Map.put(socket.assigns.pipeline_changeset.params, "transforms", transforms_params)
    pipeline_changeset =
      %Pipeline{}
      |> Pipeline.changeset(pipeline_params)
      |> Map.put(:action, :insert)

    socket = assign(socket, %{
      pipeline_changeset: pipeline_changeset,
      transform_options: transform_options,
      modal: nil,
    })
    {:noreply, socket}
  end
end
