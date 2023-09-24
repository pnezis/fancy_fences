defmodule FancyFences.Processors do
  @moduledoc """
  Common fence processors.
  """

  @doc """
  A fence processor for documenting fence processors usage.

  This can be used for documenting fence processors. It return an admonition
  block containing both the sample code and the output of the fence processor.

  ## Usage

  It expects a map with the following key-value pairs:

  - `lang` - the lang to be used for the example
  - `block` - the code block to use as an example
  - `processor` - an anonymous function with the processor that will be used.

  For example:

  ~~~
  ```fence-processor-docs
  %{
    block: "Enum.map([1, 2, 3], fn x -> 2*x end)",
    processor: fn block -> FancyFences.Processors.inspect_code(block) end
  }
  ```
  ~~~
  """
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
    `mix.exs`.
    """
    |> to_admonition_block()
  end

  defp to_admonition_block(block) do
    block =
      block
      |> String.split("\n")
      |> Enum.map(fn line -> "> " <> line end)
      |> Enum.join("\n")

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
  def inspect_code(code, _opts \\ []) do
    {result, _} = Code.eval_string(code, [], __ENV__)

    """
    ```elixir
    #{code}
    ```

    ```elixir
    #{inspect(result, pretty: true)}
    ```
    """
  end
end
