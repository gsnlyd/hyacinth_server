defmodule HyacinthWeb.PipelineLive.New do
  use HyacinthWeb, :live_view

  alias Hyacinth.Assembly
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  def mount(_params, _session, socket) do
    socket = assign(socket, %{
      pipeline_changeset: Ecto.Changeset.change(%Pipeline{}, %{}),
      transform_options: [],
      transforms: [],

      modal: nil,
    })

    {:ok, socket}
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
    pipeline_changeset = socket.assigns.pipeline_changeset
    # Retrieve existing transform changesets so we can append the new one
    # Note: If we were to instead use Ecto.Changeset.get_change/3 or get_field/3
    # then Ecto would unpack the structs from their changesets, which is not what we want.
    # The combined struct/changeset list seems to trigger a bug with validation of the
    # previous transform changesets that marks them as valid no matter what,
    # likely because the function does not seem to be meant to handle the mixed types.
    transform_changesets = Map.get(pipeline_changeset.changes, :transforms, [])

    # Get default options as a map of params
    default_driver = :sample
    options_params =
      default_driver
      |> Driver.options_changeset(%{})
      |> Ecto.Changeset.apply_action!(:insert)
      |> Map.from_struct()
    # Create new transform changeset
    new_transform_changeset = Transform.changeset(%Transform{}, %{order_index: length(transform_changesets), options: options_params})
    # Append new transform changeset to the existing transform changesets
    pipeline_changeset = Ecto.Changeset.put_assoc(pipeline_changeset, :transforms, transform_changesets ++ [new_transform_changeset])
    transform_options = socket.assigns.transform_options ++ [{default_driver, options_params}]

    socket = assign(socket, %{
      pipeline_changeset: pipeline_changeset,
      transform_options: transform_options,
    })

    {:noreply, socket}
  end

  def handle_event("delete_transform", %{"index" => index}, socket) do
    index = String.to_integer(index)

    pipeline_changeset = socket.assigns.pipeline_changeset
    transform_changesets = Map.get(pipeline_changeset.changes, :transforms, [])
    transform_changesets = List.delete_at(transform_changesets, index)
    pipeline_changeset = Ecto.Changeset.put_assoc(pipeline_changeset, :transforms, transform_changesets)

    transform_options = List.delete_at(socket.assigns.transform_options, index)

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

    transform_options = List.replace_at(transform_options, index, {driver, params})

    # Inject new options into transform changeset
    pipeline_changeset = socket.assigns.pipeline_changeset
    transform_changesets = Map.get(pipeline_changeset.changes, :transforms, [])
    transform_cs =
      transform_changesets
      |> Enum.at(index)
      |> Transform.changeset(%{options: params})
    transform_changesets = List.replace_at(transform_changesets, index, transform_cs)
    pipeline_changeset = Ecto.Changeset.put_assoc(pipeline_changeset, :transforms, transform_changesets)

    socket = assign(socket, %{
      pipeline_changeset: pipeline_changeset,
      transform_options: transform_options,
      modal: nil,
    })
    {:noreply, socket}
  end
end
