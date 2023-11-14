defmodule Fsocial.Repo do
  def get(key, default \\ 0) do
    CubDB.get(__MODULE__, key, default)
  end

  def put(key, value) do
    CubDB.put(__MODULE__, key, value)
  end
end
