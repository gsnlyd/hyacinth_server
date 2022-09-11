defmodule Hyacinth.Assembly do
  @moduledoc """
  The Assembly context defines functions for creating
  pipelines which transform datasets.
  """

  alias Hyacinth.Assembly.{Transform}

  @doc """
  Returns an `Ecto.Changeset` for tracking Transform changes.

  ## Examples

      iex> change_transform(transform)
      %Ecto.Changeset{data: %Transform{}}

  """
  def change_transform(%Transform{} = transform, attrs \\ %{}) do
    Transform.changeset(transform, attrs)
  end
end
