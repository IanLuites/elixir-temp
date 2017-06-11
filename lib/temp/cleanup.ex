defmodule Temp.Cleanup do
  @moduledoc false

  use GenServer

  ### Client API ###
  # All non documented since they should be used through Temp and not directly.

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  @spec monitor(String.t, atom, pid) :: :ok | :error
  def monitor(filename, label \\ :default, pid \\ self()) do
    GenServer.call(__MODULE__, {:monitor, pid, label, filename})
  end

  @doc false
  @spec clean(pid) :: :ok | :error
  def clean(pid) do
    GenServer.call(__MODULE__, {:cleanup, pid})
  end

  @doc false
  @spec clean(pid, atom) :: :ok | :error
  def clean(pid, label) do
    GenServer.call(__MODULE__, {:cleanup, pid, label})
  end

  ### Server Callbacks ###

  @doc false
  @spec init(:ok) :: {:ok, map}
  def init(:ok) do
    Process.flag(:trap_exit, true)

    {:ok, %{}}
  end

  @spec handle_call(term, {pid, term}, map) :: {:reply, :ok, map}
  def handle_call({:monitor, pid, label, filename}, _from, monitors) do
    Process.monitor pid

    monitors =
      Map.update(
        monitors,
        pid,
        [{label, [filename]}],
        fn files ->
          Keyword.update(files, label, [filename], &([filename | &1]))
        end
      )

    {:reply, :ok, monitors}
  end

  def handle_call({:cleanup, pid}, _from, monitors) do
    {:reply, :ok, cleanup(pid, monitors)}
  end

  def handle_call({:cleanup, pid, label}, _from, monitors) do
    {:reply, :ok, cleanup(pid, label, monitors)}
  end

  @spec handle_info(term, map) :: {:noreply, map}
  def handle_info({:DOWN, _reference, :process, pid, _type}, monitors) do
    {:noreply, cleanup(pid, monitors)}
  end

  def handle_info({:EXIT, _from, reason}, monitors) do
    terminate(reason, monitors)

    {:noreply, %{}}
  end

  def terminate(_reason, monitors) do
    remove_files monitors

    :normal
  end

  ### Helpers ###
  @spec cleanup(pid, map) :: map
  defp cleanup(pid, monitors) do
    case Map.pop(monitors, pid) do
      {nil, monitors} -> monitors
      {files, monitors} ->
        remove_files files

        monitors
    end
  end

  @spec cleanup(pid, atom, map) :: map
  defp cleanup(pid, label, monitors) do
    case Map.pop(monitors, pid) do
      {nil, monitors} -> monitors
      {files, monitors} ->
        {files_to_delete, files_left} = Keyword.pop(files, label)

        if files_to_delete, do: remove_files files_to_delete

        case files_left do
          [] -> monitors
          _ -> Map.put(monitors, pid, files_left)
        end
    end
  end

  @spec remove_files(map | keyword | list(String.t)) :: :ok
  defp remove_files(files)

  defp remove_files(files) when is_map(files) do
    files
    |> Map.values
    |> List.flatten
    |> remove_files()
  end

  defp remove_files(files) when is_list(files) do
    files # credo:disable-for-next-line
    |> Enum.map(fn {_k, v} -> v; v -> v end)
    |> List.flatten
    |> Enum.filter(&File.exists?/1)
    |> Enum.each(&File.rm/1)
  end
end
