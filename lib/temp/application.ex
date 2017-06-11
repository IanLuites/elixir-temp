defmodule Temp.Application do
  @moduledoc false
  use Application

  alias Temp.Cleanup

  @doc false
  @spec start(term, term) ::
    {:ok, pid} |
    {:ok, pid, state :: any} |
    {:error, reason :: term}
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Cleanup, []),
    ]

    opts = [strategy: :one_for_one, name: Temp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
