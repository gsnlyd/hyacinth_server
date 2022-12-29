defmodule Hyacinth.Validators do
  import Ecto.Changeset

  @doc """
  Parses a comma-separated string field into an array field for
  a changeset.

  ## Examples

      def changeset(struct, attrs) do
        struct
        |> cast(attrs, [:some_string_field])
        |> validate_required([:some_string_field])
        |> parse_comma_separated_string(:some_string_field, :some_string_array_field)
      end

  """
  @spec parse_comma_separated_string(%Ecto.Changeset{}, atom, atom, keyword) :: %Ecto.Changeset{}
  def parse_comma_separated_string(%Ecto.Changeset{} = changeset, string_field, array_field, opts \\ []) do
    if changeset.valid? do
      string = get_field(changeset, string_field)

      array =
        string
        |> String.split(",", trim: true)
        |> Enum.map(&String.trim/1)

      changeset = put_change(changeset, array_field, array)
      if opts[:keep_string] do
        changeset
      else
        delete_change(changeset, string_field)
      end
    else
      changeset
    end
  end
end
