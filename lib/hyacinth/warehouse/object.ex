defmodule Hyacinth.Warehouse.Object do
  use Hyacinth.Schema
  import Ecto.Changeset

  alias Hyacinth.Warehouse.{Object, DatasetObject}

  schema "objects" do
    field :hash, :string
    field :type, Ecto.Enum, values: [:blob, :tree]

    field :name, :string
    field :file_type, Ecto.Enum, values: [:png, :dicom, :nifti]

    belongs_to :parent_tree, Object

    has_many :children, Object, foreign_key: :parent_tree_id

    has_many :dataset_objects, DatasetObject
    has_many :datasets, through: [:dataset_objects, :dataset]

    timestamps()
  end

  @doc false
  def create_changeset(object, attrs) do
    object
    |> cast(attrs, [:hash, :type, :name, :file_type])
    |> validate_required([:hash, :type, :name, :file_type])
    |> cast_assoc(:children, with: &create_changeset/2)
    |> validate_object_type()
  end

  defp validate_object_type(%Ecto.Changeset{} = changeset) do
    case get_field(changeset, :children) do
      children when is_list(children) and length(children) > 0 ->
        if get_change(changeset, :type) != :tree do
          add_error(changeset, :type, "must be tree if object has children")
        else
          changeset
        end

      children when is_list(children) and length(children) == 0 ->
        if get_change(changeset, :type) != :blob do
          add_error(changeset, :type, "must be blob if object has no children")
        else
          changeset
        end
    end
  end
end
