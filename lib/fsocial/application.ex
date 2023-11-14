defmodule Fsocial.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FsocialWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:fsocial, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Fsocial.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Fsocial.Finch},
      # Start a worker by calling: Fsocial.Worker.start_link(arg)
      # {Fsocial.Worker, arg},
      # Start to serve requests, typically the last entry
      FsocialWeb.Endpoint,
      {CubDB, name: Fsocial.Repo, data_dir: "data"},
      {Registry, name: Fsocial.UserRegistry, keys: :unique},
      Fsocial.Storage,
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: Fsocial.DynamicSupervisors}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fsocial.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FsocialWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
