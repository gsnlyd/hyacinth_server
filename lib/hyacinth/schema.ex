defmodule Hyacinth.Schema do
  @moduledoc """
  Defines a custom Schema macro which forces utc_datetime_usec timestamps by default.
  Replaces Ecto.Schema in schema modules for this application.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
