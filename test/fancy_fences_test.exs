defmodule FancyFencesTest do
  use ExUnit.Case
  doctest FancyFences

  defmodule Processors do
    def replace_with_list(_code) do
      """
      * a list
      * with three
        * elements
      """
    end

    def replace_with_replace(_code) do
      """
      ```replace
      another code block
      ```
      """
    end

    def replace_composite(_code) do
      """
      ```list
      to be replaced by a list
      ```

      with some **inline** `markdown`

      ```replace
      to be replaced by replaced
      ```
      """
    end
  end

  describe "to_ast/2" do
    test "with no fences config" do
      markdown = """
      ```elixir
      IO.puts "hello world"
      ```
      """

      assert FancyFences.to_ast(markdown, []) == ExDoc.Markdown.to_ast(markdown)
    end

    test "replace code block with list" do
      markdown = """
      ```replace
      anything
      ```
      """

      expected = """
      * a list
      * with three
        * elements
      """

      opts = [fences: %{"replace" => {Processors, :replace_with_list, []}}]

      assert FancyFences.to_ast(markdown, opts) == ExDoc.Markdown.to_ast(expected)
    end

    test "no recursion allowed" do
      markdown = """
      ```replace
      a code block
      ```
      """

      expected = """
      ```replace
      another code block
      ```
      """

      opts = [fences: %{"replace" => {Processors, :replace_with_replace, []}}]

      assert FancyFences.to_ast(markdown, opts) == ExDoc.Markdown.to_ast(expected)
    end

    test "unwraps nested fences" do
      markdown = """
      ```composite
      a code block
      ```
      """

      expected = """
      * a list
      * with three
        * elements

      with some **inline** `markdown`

      ```replace
      another code block
      ```
      """

      opts = [
        fences: %{
          "list" => {Processors, :replace_with_list, []},
          "composite" => {Processors, :replace_composite, []},
          "replace" => {Processors, :replace_with_replace, []}
        }
      ]

      assert FancyFences.to_ast(markdown, opts) == ExDoc.Markdown.to_ast(expected)
    end
  end
end
