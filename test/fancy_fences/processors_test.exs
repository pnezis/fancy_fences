defmodule FancyFences.ProcessorsTest do
  use ExUnit.Case

  defmodule Foo do
    def sample_processor(code) do
      """
      Prefix

      ```elixir
      #{code}
      ```

      Suffix
      """
    end
  end

  describe "fence_processor_doc/1" do
    test "renders an admonition block" do
      block = """
        %{
          block: "1 + 1",
          processor: fn block -> FancyFences.Processors.inspect_code(block) end
        }
      """

      expected = """
      > #### Embedded code {: .info}
      >
      > A fenced code block of the form:
      >
      > ~~~
      > ```lang
      > 1 + 1
      > ```
      > ~~~
      >
      > will be transformed to:
      >
      > ```elixir
      > 1 + 1
      > ```
      >
      > ```elixir
      > 2
      > ```
      >
      >
      > where `lang` the defined code language for this fence processor in your
      > `mix.exs`.\
      """

      assert FancyFences.Processors.fence_processor_doc(block) == expected
    end
  end

  describe "inspect_code/2" do
    test "with valid expression" do
      result =
        for x <- 1..3 do
          %{x: x}
        end

      block = """
      for x <- 1..3 do
        %{x: x}
      end
      """

      expected = """
      ```elixir
      #{block}
      ```

      ```elixir
      #{inspect(result, pretty: true)}
      ```
      """

      assert FancyFences.Processors.inspect_code(block) == expected
    end

    test "with format set to true" do
      block = """
      for x <- 1..3 do
      2*x
      end
      """

      expected = """
      ```elixir
      for x <- 1..3 do
        2 * x
      end
      ```

      ```elixir
      [2, 4, 6]
      ```
      """

      assert FancyFences.Processors.inspect_code(block, format: true) == expected
    end
  end
end
