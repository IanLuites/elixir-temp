defmodule Temp do
  @moduledoc ~S"""
  Creation and cleanup of temporary files and directories.
  """

  alias Temp.Cleanup

  # Sets random string, increase for longer file names.
  @random_strength 11

  # Number of attempts before unique name generation fails.
  # (Prevents [highly unlikely] endless generation loops.)
  @generation_limit 10

  ### Creation ###

  @doc ~S"""
  Creates a temporary file.

  The file will be deleted, when the process dies.
  See `Temp.cleanup/1` to manually remove files.

  Returns `{:ok, filename}` on success; otherwise returns `{:error, reason}`.

  The following options can be passed to customize file creation:

    * `:directory`, the directory to create the files in. (Default: :directory config or "tmp".)
    * `:suffix`, suffix for the file; can be used to set extensions.
    * `:prefix`, prefix for the file.
    * `:label`, label the temporary file. Useful for grouping and manually cleanup. (Default: `:default`.)

  """
  @spec file(Keyword.t) :: {:ok, String.t} | {:error, atom}
  def file(options \\ []) do
    with directory <- get_directory(options),
         :ok <- File.mkdir_p(directory),
         {:ok, filename} <- generate(directory, options),
         :ok <- File.touch(filename)
    do
      Cleanup.monitor filename, (options[:label] || :default)

      {:ok, filename}
    end
  end

  @doc ~S"""
  Creates a temporary file.

  The file will be deleted, when the process dies.
  See `Temp.cleanup/1` to manually remove files.

  Returns the filename on success; otherwise returns raises a `RuntimeError`.

  For options see: `Temp.file/1`.
  """
  @spec file!(Keyword.t) :: String.t
  def file!(options \\ []) do
    case file(options) do
      {:ok, filename} -> filename
      {:error, reason} -> raise RuntimeError, to_string(reason)
    end
  end

  ### Cleanup ###

  @doc ~S"""
  Removes all files and directories for the [current] process.

  See `Temp.cleanup/2` to manually remove files with a specific label.
  """
  @spec cleanup :: :ok | :error
  def cleanup do
    Cleanup.clean self()
  end

  @doc ~S"""
  Removes all files and directories with the given `label` for the [current] process.

  Leaves all other files and directories to be cleaned up at process dead.
  """
  @spec cleanup(atom) :: :ok | :error
  def cleanup(label) do
    Cleanup.clean self(), label
  end

  ### Helpers ###

  @spec get_directory(Keyword.t) :: String.t
  defp get_directory(options) do
    (options[:directory] || Application.get_env(:temp, :directory, "tmp"))
  end

  @spec generate(String.t, Keyword.t, integer)
    :: {:ok, String.t} | {:error, :unique_generation_limit}
  defp generate(directory, options, attempt \\ 0)

  defp generate(directory, options, attempt) when attempt < @generation_limit do
    name = directory <> "/" <> generate_name(options)

    if File.exists?(name) do
      generate(directory, options, attempt + 1)
    else
      {:ok, name}
    end
  end

  defp generate(_directory, _options, _attempt), do: {:error, :unique_generation_limit}

  @spec generate_name(Keyword.t) :: String.t
  defp generate_name(options) do
    name =
      <<:os.system_time(:micro_seconds)::64>>
      |> Kernel.<>(List.to_string(:os.getpid))
      |> Kernel.<>(:crypto.strong_rand_bytes(@random_strength))
      |> Base.url_encode64

    (options[:prefix] || "") <> name <> (options[:suffix] || "")
  end
end
