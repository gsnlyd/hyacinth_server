defmodule Hyacinth.ViewerState do
  use Agent

  alias Phoenix.PubSub

  @spec get_name(String.t) :: {:global, String.t}
  defp get_name(viewer_session_id) when is_binary(viewer_session_id), do: {:global, "viewer_state:#{viewer_session_id}"}

  @doc """
  Starts a linked ViewerState agent.

  ## Examples

      iex> session_id = Ecto.UUID.generate()
      iex> {:ok, pid} = ViewerState.start_link(%{hello: "world"}, session_id)

  """
  @spec start_link(map, String.t) :: Agent.on_start
  def start_link(initial_state, viewer_session_id) when is_map(initial_state) do
    Agent.start_link(fn -> initial_state end, name: get_name(viewer_session_id))
  end

  @doc """
  Checks whether the given session has a ViewerState agent
  process.

  ## Examples

      iex> ViewerState.exists?(some_session_id)
      true

      iex> ViewerState.exists?(some_other_session_id)
      false

  """
  @spec exists?(String.t) :: boolean
  def exists?(viewer_session_id) do
    {:global, name} = get_name(viewer_session_id)
    case :global.whereis_name(name) do
      :undefined -> false
      pid when is_pid(pid) -> true
    end
  end

  @doc """
  Gets the current state.

  ## Examples

      iex> ViewerState.get_state(some_session_id)
      %{hello: "world"}

  """
  @spec get_state(String.t) :: map
  def get_state(viewer_session_id) do
    Agent.get(get_name(viewer_session_id), &(&1))
  end

  @doc """
  Merges the given new_state map into the current state, broadcasts
  the update via PubSub, and returns the new state.

  Note: `Phoenix.PubSub.broadcast_from!/5` is used so that the caller
  will not receive the broadcast.

  See `Map.merge/2` for details.

  ## Examples

      iex> ViewerState.get_state(some_session_id)
      %{hello: "earth"}

      iex> ViewerState.merge_state(some_session_id, %{hello: "world", foo: "bar"})
      %{hello: "world", foo: "bar"}

  """
  @spec merge_state(String.t, map) :: map
  def merge_state(viewer_session_id, new_state) when is_map(new_state) do
    Agent.update(get_name(viewer_session_id), fn old_state ->
      Map.merge(old_state, new_state)
    end)

    broadcast_update(viewer_session_id)
    get_state(viewer_session_id)
  end

  def subscribe(viewer_session_id), do: PubSub.subscribe(Hyacinth.PubSub, "viewer:#{viewer_session_id}")

  defp broadcast_update(viewer_session_id) do
    state = get_state(viewer_session_id)
    PubSub.broadcast_from!(Hyacinth.PubSub, self(), "viewer:#{viewer_session_id}", {:viewer_updated, state})
  end
end
