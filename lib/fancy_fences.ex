defmodule FancyFences do
  @moduledoc ~S'''
  Post-process code blocks in your markdown docs.

  `FancyFences` is a tiny wrapper around `ExDoc.Markdown.Earmark` that post processes
  fenced markdown code blocks. You can use it to:

  - Ensure that the code examples are up to date with your code.
  - Automatically inject the output of the code block.
  - Enrich your docs with VegaLite plots or mermaid charts.
  - Use it in a more hacky way when interpolation is not possible.

  ## Usage

  In order to use `FancyFences` you need to set the `:markdown_processor` option
  in the `:docs` section as following:

      docs: [
        markdown_processor: {FancyFences, [fences: processors]}
      ]

  where `processors` is expected to be a map with all processors that will be
  applied on code blocks. The keys of the `proecessors` map are the code
  _language_ on which this specific processor will be applied. The values of the
  `processors` map are expected to be `mfa` tuples with the function that will be
  applied. For example the following configuration:

      docs: [
        markdown_processor: {FancyFences, [fences: fancy_processors()]}
      ]

      defp fancy_processors do
        %{
          "elixir" => {FancyFences.Processors, :format_code, []},
          "elixir::inspect" => FancyFences.Processors, :inspect_code, [])
        }
      end

  will apply two processors:

  - Each `elixir` code block will be post-processed using the `FancyFences.Processors.format_code/2`
  which will format the inline code.
  - Each `elixir::inspect` code block will be post-processed using the `FancyFences.Processors.inspect_code/2`
  which will replace the existing code block with two blocks:
    - An `:elixir` code block including the initial code
    - A second `:elixir` block with the output of the evaluation of the first block.

  This is useful for evaluating during docs generation fenced code blocks, without having to
  manually write the expected output, also ensuring that your docs are always up to date, since
  if the underlying functions change then `mix docs` will fail.

  > #### Recursive application of fence processors {: .tip}
  >
  > Norice that fence processors are applied recursively. This means that in the previous
  > example the `elixir` injected code blocks will also be processed by the format
  > processor, ensuring that both the raw code input and the evaluation output will be
  > properly formatted.

  ## Fence processors

  Fence processors are simple elixir functions that expect as input a string corresponding to
  the code in the markdown code block and an optional keyword list and return a markdown that
  will be injected in the docs.

  ### Writing a custom processor

  Let's see a real world example, how [`Tucan`](https://hexdocs.pm/tucan/Tucan.html) uses
  `FancyFences` in order to render both the sample code and the corresponding `vega-lite`
  specification.


  `Tucan` defines a fence processor that it expects a code blocks that returns a `VegaLite`
  struct and it generates two code blocks:

  - The original code formatted.
  - The `json` `vega-lite` specification of the `VegaLite` struct.

  ~~~elixir
  def tucan(code, _opts \\ []) do
    {%VegaLite{} = plot, _} = Code.eval_string(code, [], __ENV__)

    spec = VegaLite.to_spec(plot)

    """
    ```elixir
    #{Code.format_string!(code)}
    ```

    ```vega-lite
    #{Jason.encode!(spec)}
    ```
    """
  end
  ~~~

  In order to enable it you only need to configure to which markdown code _language_ this
  will be applied. In the `Tucan` case it is applied on code blocks marked as `tucan`:

      docs: [
        markdown_processor:
          {FancyFences,
           [
             fences: %{
               "tucan" => {Tucan.Docs, :tucan, []}
             }
           ]},
      ]
  '''

  @behaviour ExDoc.Markdown

  @impl ExDoc.Markdown
  def available?, do: ExDoc.Markdown.Earmark.available?()

  @impl ExDoc.Markdown
  def to_ast(text, opts) do
    to_ast(text, opts, [])
  end

  defp to_ast(text, opts, applied_processors) do
    {_fences_opts, doc_opts} = Keyword.split(opts, [:fences])

    text
    |> ExDoc.Markdown.Earmark.to_ast(doc_opts)
    |> Enum.reduce([], fn block, acc ->
      acc ++ maybe_apply_fence_processors(block, opts, applied_processors)
    end)
  end

  defp maybe_apply_fence_processors(
         {:blockquote, attrs, content, meta},
         opts,
         applied_processors
       ) do
    content =
      Enum.reduce(content, [], fn block, acc ->
        acc ++ maybe_apply_fence_processors(block, opts, applied_processors)
      end)

    [{:blockquote, attrs, content, meta}]
  end

  defp maybe_apply_fence_processors(
         {:pre, _pre_attrs, [{:code, [class: fence], content, _code_meta}], _pre_meta} = block,
         opts,
         applied_processors
       ) do
    fence_processors = Keyword.get(opts, :fences, %{})

    cond do
      # we want to avoid infinite recursion here, just return the block
      fence in applied_processors ->
        [block]

      # if we have defined a custom fence processor apply it (recursively)
      Map.has_key?(fence_processors, fence) ->
        # a configured fence processor must be an mfa tuple
        {module, function, args} = fence_processors[fence]

        code = Enum.join(content, "\n")

        apply(module, function, [code | args])
        |> to_ast(opts, [fence | applied_processors])

      # in any other case return the original block
      true ->
        [block]
    end
  end

  defp maybe_apply_fence_processors(block, _opts, _applied_processors), do: [block]
end
