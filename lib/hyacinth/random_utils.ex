defmodule Hyacinth.RandomUtils do
  @moduledoc """
  This module contains random functions which use a separate process
  to seed the random number generator, ensuring determinism.
  """

  @doc """
  Takes `count` random items from `enumerable`.

  Same as `Enum.take_random/2`, but seeded by `seed`.

  ## Examples

      iex> take_random_seeded(1234, 1..10, 2)
      [3, 1]

  """
  @spec take_random_seeded(integer, Enum.t, integer) :: list
  def take_random_seeded(seed, enumerable, count) do
    task = Task.async(fn ->
      :rand.seed(:exsss, {seed, seed, seed})
      Enum.take_random(enumerable, count)
    end)

    Task.await(task)
  end

  @doc """
  Shuffles `enumerable`.

  Equivalent to calling `take_random_seeded/3`
  with `count` set to the length of the enumerable.

  ## Examples

      iex> shuffle_seeded(1234, [10, 20, 30])
      [20, 10, 30]

  """
  @spec shuffle_seeded(integer, Enum.t) :: list
  def shuffle_seeded(seed, enumerable) do
    take_random_seeded(seed, enumerable, length(enumerable))
  end
end
