defmodule Fsocial.Storage do
  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def get(key) do
    __MODULE__
    |> ETS.KeyValueSet.wrap_existing!()
    |> ETS.KeyValueSet.get!(key)
  end

  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  def init(_init_arg) do
    set =
      ETS.KeyValueSet.new!(
        name: __MODULE__,
        protection: :public,
        write_concurrency: true,
        read_concurrency: true
      )

    {:ok, set}
  end

  def handle_call({:put, key, value}, from, set) do
    GenServer.reply(from, :ok)
    set = ETS.KeyValueSet.put!(set, key, value)
    {:noreply, set}
  end
end
