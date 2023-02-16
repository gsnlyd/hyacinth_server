defmodule Hyacinth.Utils do
  @doc ~S"""
  Transforms a list of lists of strings (a list of rows) into a
  comma-separated CSV in the form of a string.

  Ignores any `nil` entries.

  ## Examples

      iex> my_rows = [
        ["hello", nil, "world"],
        ["abc", nil, "123"],
      ]

      iex> rows_to_csv_string(my_rows)
      "hello,world\nabc,123"

  """
  @spec rows_to_csv_string([[String.t]]) :: String.t
  def rows_to_csv_string(rows) when is_list(rows) do
    rows
    |> Enum.map(fn row when is_list(row) ->
      row
      |> Enum.filter(&(&1 != nil))
      |> Enum.join(",")
    end)
    |> Enum.join("\n")
  end
end
