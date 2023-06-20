defmodule FancyFences do
  @moduledoc """
  A tiny wrapper around `ExDoc.Markdown.Earmark` that supports fancy fences.
  """

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
