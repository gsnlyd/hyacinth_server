defmodule Hyacinth.Warehouse.Store do
  @moduledoc """
  Utilities for hashing, ingesting, and retrieving files from the object store.

  This module consists of lower-level utilities which work directly on files.
  See `Hyacinth.Warehouse.Packer` for higher-level utilities which work
  with `Hyacinth.Warehouse.Object` structs.
  """

  require Logger

  @hash_algorithm :sha256

  @doc """
  Returns the hash of the contents of the file at the given path.
  """
  def hash_file(path) when is_binary(path) do
    hash_initial_state = :crypto.hash_init(@hash_algorithm)

    hash =
      File.stream!(path, [], 2048)
      |> Enum.reduce(hash_initial_state, fn file_chunk, cur_hash_state ->
        :crypto.hash_update(cur_hash_state, file_chunk)
      end)
      |> :crypto.hash_final()

    Atom.to_string(@hash_algorithm) <> ":" <> Base.encode16(hash, case: :lower)
  end

  @doc """
  Returns the hash of a list of child hashes.
  """
  def hash_hashes(hashes) when is_list(hashes) do
    hashes_concat =
      hashes
      |> Enum.map(fn hash ->
        {_algo, hash} = split_hash(hash)
        hash
      end)
      |> Enum.sort()
      |> Enum.join()

    hash = :crypto.hash(@hash_algorithm, hashes_concat)
    Atom.to_string(@hash_algorithm) <> ":" <> Base.encode16(hash, case: :lower)
  end

  @doc """
  Splits a hash into its algorithm and value.
  """
  def split_hash(hash) when is_binary(hash) do
    [hash_algo, hash_value] = String.split(hash, ":")
    {hash_algo, hash_value}
  end

  @doc """
  Returns the path to the objects directory where objects are saved.
  """
  def get_objects_dir do
    Application.fetch_env!(:hyacinth, :warehouse_path)
  end

  @doc """
  Returns the path to the subdirectory where objects with the given
  hash algorithm are stored.
  """
  def get_hash_algo_dir(hash_algo) when hash_algo in ["sha256"] do
    Path.join get_objects_dir(), hash_algo
  end

  @doc """
  Returns the path where an object with the given hash will be stored.
  """
  def get_object_path_from_hash(hash) when is_binary(hash) do
    {hash_algo, hash_value} = split_hash(hash)
    Path.join get_hash_algo_dir(hash_algo), hash_value
  end

  defp ensure_directories(hash) when is_binary(hash) do
    objects_dir = get_objects_dir()
    if not File.exists?(objects_dir) do
      File.mkdir!(objects_dir)
      Logger.debug "Created objects directory: #{objects_dir}"
    end

    {hash_algo, _hash_value} = split_hash(hash)
    hash_dir = get_hash_algo_dir(hash_algo)
    if not File.exists?(hash_dir) do
      File.mkdir!(hash_dir)
      Logger.debug "Created hash (#{hash_algo}) subdirectory: #{hash_dir}"
    end

    :ok
  end

  @doc """
  Ingests (copies) a file into the object store.
  Returns the hash of the file.
  """
  def ingest_file!(path) when is_binary(path) do
    if not File.exists?(path), do: raise "File at path #{path} does not exist"
    if File.dir?(path), do: raise "Path #{path} points to a directory - only files are allowed"

    hash = hash_file(path)
    ensure_directories(hash)

    dest_path = get_object_path_from_hash(hash)
    bytes_copied = File.copy!(path, dest_path)
    Logger.debug "Successfully copied #{bytes_copied} bytes from #{path} to #{dest_path}"

    hash
  end

  @doc """
  Returns the transform temp dir.
  """
  def get_transform_temp_dir do
    Application.fetch_env!(:hyacinth, :transform_path)
  end

  @doc """
  Returns a subdirectory under the main transform temp dir for the given UUID.
  """
  def get_temp_dir_from_uuid(uuid) when is_binary(uuid) do
    Path.join get_transform_temp_dir(), uuid
  end

  @doc """
  Creates a subdirectory under the transform temp root
  named with a randomly-generated UUID. Returns the path
  of the newly-created directory.
  """
  @spec create_temp_dir() :: String.t
  def create_temp_dir() do
    temp_dir_path = get_temp_dir_from_uuid(Ecto.UUID.generate())
    File.mkdir!(temp_dir_path)
    Logger.debug "Created temporary dir: #{temp_dir_path}"

    temp_dir_path
  end

  @doc """
  Copies an object file from the object store to the
  given destination path.
  """
  @spec retrieve!(String.t, String.t) :: :ok
  def retrieve!(hash, dest_path) when is_binary(hash) and is_binary(dest_path) do
    if File.exists?(dest_path), do: raise "File already exists at dest path: #{dest_path}"
    unless String.starts_with?(Path.expand(dest_path), get_transform_temp_dir()), do: raise "Dest path is not in transform temp dir: #{dest_path}"

    path = get_object_path_from_hash(hash)
    if not File.exists?(path), do: raise "File with hash #{hash} does not exist in the store!"

    bytes_copied = File.copy!(path, dest_path)
    Logger.debug "Successfully unpacked #{bytes_copied} bytes from #{path} to #{dest_path}"

    :ok
  end
end
