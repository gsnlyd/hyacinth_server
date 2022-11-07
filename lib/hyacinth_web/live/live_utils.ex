defmodule HyacinthWeb.LiveUtils do
  @doc """
  Returns the given duration formatted as
  a short string.

  ## Examples

      iex> format_time(30)
      "30s"

      iex> format_time(99)
      "1m 39s"

      iex> format_time(3601)
      "1h"

  """
  @spec format_time(integer) :: String.t
  def format_time(seconds) do
    cond do
      seconds < 60 ->
        "#{seconds}s"
      seconds < (60 * 60) ->
        "#{div(seconds, 60)}m #{rem(seconds, 60)}s"
      true ->
        "#{div(seconds, 60 * 60)}h"
    end
  end

  @doc """
  Checks whether the given string or list of strings
  contains the given search string (case-insensitive).

  If a list of strings is passed as the first parameter,
  this function returns true if any of those strings
  contains the search string.

  ## Examples

      iex> contains_search?("hello world", "ELLO WOR")
      true

      iex> contains_search?("hello world", "foo")
      false

      iex> contains_search?(["hello world", "Foo Bar"], "foo")
      true

      iex> contains_search?(["hello world", "Foo Bar"], "baz")
      false

  """
  @spec contains_search?(String.t, String.t) :: boolean
  def contains_search?(string, search) when is_binary(string) and is_binary(search) do
    String.contains?(String.downcase(string), String.downcase(search))
  end

  @spec contains_search?([String.t], String.t) :: boolean
  def contains_search?(strings, search) when is_list(strings) and is_binary(search) do
    Enum.any?(strings, &contains_search?(&1, search))
  end

  @doc """
  Returns true if the given value is equal to
  the given option, or if the given option
  is :all.

  ## Examples

      iex> value_matches?(:some_value, :some_value)
      true

      iex> value_matches?(:some_value, :all)
      true

      iex> value_matches?(:some_value, :another_value)
      false

  """
  @spec value_matches?(atom, atom) :: boolean
  def value_matches?(value, option) when is_atom(value) and is_atom(option) do
    option == :all or option == value
  end

  @doc """
  Extracts the values from a schema's Enum field and
  humanizes them.

  Values are returned as tuples containing a humanized
  string and the value atom.

  ## Examples

      iex> humanize_enum(SomeSchemaModule, :some_field)
      [
        {"Some field", :some_field},
        {"Another field", :another_field}
      ]

  """
  @spec humanize_enum(module, atom) :: [{String.t, atom}]
  def humanize_enum(schema, field) do
    Enum.map(Ecto.Enum.values(schema, field), fn value ->
      {Phoenix.HTML.Form.humanize(value), value}
    end)
  end
end
