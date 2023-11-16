defmodule Fsocial.User do
  use GenServer

  require Logger

  @type username :: String.t()
  @type followers :: non_neg_integer()
  @type state :: %{
          username: username() | nil,
          followers: followers() | nil,
          timer: reference() | nil,
          avatar: String.t() | nil
        }

  defstruct [:username, :followers, :timer]

  @persist_interval_ms :timer.seconds(10)
  @persist_followers_every 1000

  @spec start_child(username()) :: DynamicSupervisor.on_start_child()
  def start_child(username) do
    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {Fsocial.DynamicSupervisors, self()}},
      Fsocial.User.child_spec(username)
    )
  end

  @spec child_spec(username()) :: Supervisor.child_spec()
  def child_spec(username) do
    %{
      id: "#{__MODULE__}_#{username}",
      start: {__MODULE__, :start_link, [username]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  @spec start_link(username()) :: GenServer.on_start()
  def start_link(username) do
    case GenServer.start_link(__MODULE__, username, name: via_tuple(username)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  @spec follow(username()) :: :ok
  def follow(username) do
    GenServer.call(via_tuple(username), :follow)
  end

  @spec followers(username()) :: followers()
  def followers(username) do
    Fsocial.Storage.get(username)
  end

  @impl GenServer
  def init(username) do
    Process.flag(:trap_exit, true)
    followers = Fsocial.Repo.get(username, 0)
    Fsocial.Storage.put(username, followers)
    timer = Process.send_after(self(), :persist, @persist_interval_ms)

    {:ok, %{username: username, followers: followers, timer: timer}}
  end

  @impl GenServer
  def handle_call(:follow, from, state) do
    GenServer.reply(from, :ok)

    state =
      Map.update!(state, :followers, fn followers ->
        followers + 1
      end)

    Fsocial.Storage.put(state.username, state.followers)

    state =
      if rem(state.followers, @persist_followers_every) == 0 do
        Process.cancel_timer(state.timer)
        persist(state)
      else
        state
      end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:persist, state) do
    {:noreply, persist(state)}
  end

  @impl GenServer
  def terminate(_reason, state) do
    Fsocial.Repo.put(state.username, state.followers)
  end

  @spec persist(state()) :: state()
  def persist(%{followers: 0} = state) do
    state
  end

  def persist(state) do
    Fsocial.Repo.get_and_update(state.username, state.followers)
    %{state | timer: Process.send_after(self(), :persist, @persist_interval_ms)}
  end

  @spec via_tuple(username()) :: {:via, Registry, {Fsocial.UserRegistry, username()}}
  def via_tuple(username) do
    {:via, Registry, {Fsocial.UserRegistry, username}}
  end
end
