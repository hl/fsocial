defmodule Fsocial.Storage do
  use GenServer

  @type key :: any()
  @type value :: any()

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec get(key()) :: value()
  def get(key) do
    __MODULE__
    |> ETS.KeyValueSet.wrap_existing!()
    |> ETS.KeyValueSet.get!(key)
  end

  @spec put(key(), value()) :: :ok
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  @impl GenServer
  def init(_init_arg) do
    ETS.KeyValueSet.new(
      name: __MODULE__,
      protection: :public,
      write_concurrency: true,
      read_concurrency: true
    )
  end

  @impl GenServer
  def handle_call({:put, key, value}, from, set) do
    GenServer.reply(from, :ok)
    set = ETS.KeyValueSet.put!(set, key, value)
    {:noreply, set}
  end
end
