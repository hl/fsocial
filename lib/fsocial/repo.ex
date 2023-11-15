defmodule Fsocial.Repo do
  @spec get(CubDB.key(), term()) :: CubDB.value()
  def get(key, default \\ 0) do
    CubDB.get(__MODULE__, key, default)
  end

  @spec put(CubDB.key(), CubDB.value()) :: CubDB.value()
  def put(key, value) do
    CubDB.put(__MODULE__, key, value)
  end

  @spec get_and_update(CubDB.key(), CubDB.value()) :: :ok
  def get_and_update(key, value) do
    CubDB.get_and_update(__MODULE__, key, fn _existing_value ->
      {:ok, value}
    end)
  end
end
