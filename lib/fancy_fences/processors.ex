defmodule FancyFences.Processors do
  @moduledoc """
  Common fence processors.
  """

  @doc ~S'''
  A fence processor for documenting fence processors usage.

  This can be used for documenting fence processors. It return an admonition
  block containing both the sample code and the output of the fence processor.

  ## Usage

  It expects a map with the following key-value pairs:

  - `block` - the code block to use as an example
  - `processor` - an anonymous function with the processor that will be used.

  For example:

  ~~~
  ```fence-processor
  %{
    block: "Enum.map([1, 2, 3], fn x -> 2*x end)",
    processor: fn block -> FancyFences.Processors.inspect_code(block) end
  }
  ```
  ~~~

  ```fence-processor
  %{
    block: """
    %{
       block: "1 + 1",
       processor: fn block -> 
         "**Code:** `"<> block <> "`"
       end
    }
    """,
    processor: fn block -> FancyFences.Processors.fence_processor_doc(block) end
  }
  ```

  Notice that above we used `fence_processor_doc/1` to document itself, that's why
  we have the nested admonition block.
  '''
  def fence_processor_doc(code) do
    {result, _} = Code.eval_string(code, [], __ENV__)
    %{block: block, processor: processor} = result

    processed = processor.(block)

    """
    A fenced code block of the form:

    ~~~
    ```lang
    #{block}
    ```
    ~~~

    will be transformed to:

    #{processed}

    where `lang` the defined code language for this fence processor in your
    `mix.exs`.\
    """
    |> to_admonition_block()
  end

  defp to_admonition_block(block) do
    block =
      block
      |> String.split("\n")
      |> Enum.map(fn line -> "> " <> line end)
      |> Enum.map(&String.trim/1)
      |> Enum.join("\n")
      |> String.trim()

    """
    > #### Embedded code {: .info}
    >
    """ <> block
  end

  @doc """
  Embeds the original code and the evaluated result.

  ## Options

  * `:format` (`boolean`) - If set to `true` the code blocks will
    be formatted before inection. Defaults to `false`.

  ```fence-processor
  %{
    block: "Enum.map([1, 2, 3, 4], fn x -> 2*x end)",
    processor: fn block -> FancyFences.Processors.inspect_code(block) end
  }
  ```
  """
  def inspect_code(code, opts \\ []) do
    opts = Keyword.validate!(opts, format: false)

    {result, _} = Code.eval_string(code, [], __ENV__)

    """
    ```elixir
    #{maybe_format(code, opts[:format])}
    ```

    ```elixir
    #{inspect(result, pretty: true)}
    ```
    """
  end

  @doc ~S'''
  Formats the given code block.

  ```fence-processor
  %{
    block: """
    for x <- [1, 2, 3] do
    2 * x
    end
    """,
    processor: fn block -> FancyFences.Processors.format_code(block) end
  }
  ```
  '''
  def format_code(code) do
    """
    ```elixir
    #{maybe_format(code, true)}
    ```
    """
  end

  defp maybe_format(code, false), do: code
  defp maybe_format(code, true), do: Code.format_string!(code)
end
