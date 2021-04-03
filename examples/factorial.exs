defmodule Factorial do
  @moduledoc ~S"""
  A module that provides a slow factorial calculation,
  with a minor bug when calling factorial of `8`.

  Factorial example: 3! = 3 * 2 * 1
  """

  @sleep 100

  def sleepy_factorial(8) do
    raise "oh noes"
  end

  def sleepy_factorial(n) when n > 0 do
    :timer.sleep(@sleep)
    n * sleepy_factorial(n - 1)
  end

  def sleepy_factorial(0) do
    :timer.sleep(@sleep)
    1
  end
end
