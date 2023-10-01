# FancyFences

[![Actions Status](https://github.com/pnezis/fancy_fences/actions/workflows/elixir.yml/badge.svg)](https://github.com/pnezis/fancy_fences/actions)
[![Package](https://img.shields.io/badge/-Package-important)](https://hex.pm/packages/fancy_fences)
[![Documentation](https://img.shields.io/badge/-Documentation-blueviolet)](https://hexdocs.pm/fancy_fences)

`FancyFences` is a markdown processor on top of [`EarmarkParser`](https://github.com/pragdave/earmark)
(the default markdown processor user by [`ExDoc`](https://github.com/elixir-lang/ex_doc). You can
use it to conditionally post-process code blocks allowing you to:

- Ensure that the code examples are valid
- Format code blocks
- Evaluate code blocks and include the output in the documenation, for example you can:
  - add the `inspect` ouptut of a code block in order to have up to date code samples in your docs
  - auto-generate vega-lite or mermaid plots
  - use it instead of interplation for evaluating functions within the current module.

## Usage

In order to use `FancyFences` you need to set the `:markdown_processor` option
in the `:docs` section as following:

```elixir
docs: [
  markdown_processor: {FancyFences, [fences: processors]}
]
```

where `processors` defines the code blocks processors.

```elixir
docs: [
  markdown_processor: {FancyFences, [fences: fancy_processors()]}
]

defp fancy_processors do
  %{
    "elixir" => {FancyFences.Processors, :format_code, []},
    "inspect" => {FancyFences.Processors, :inspect_code, []},
    "vl" => {MyProcessors, :vega_lite, []},
    "mermaid" => {MyProcessors, :mermaid, []}
  }
end
```

will apply the following processors:

- Each `elixir` code block will be post-processed using the `FancyFences.Processors.format_code/2`
which will format the inline code.
- Each `inspect` code block will be post-processed using the `FancyFences.Processors.inspect_code/2`
which will replace the existing code block with two blocks:
  - An `:elixir` code block including the initial code
  - A second `:elixir` block with the output of the evaluation of the first block.
- Each `vl` block will apply a custom processor that evaluates the inline code
block and replaces it with the original block and the evaluated vega-lite spec.
You can see such a processor used throughout [`Tucan` docs](https://hexdocs.pm/tucan/Tucan.html)
- Similarly for the mermaid blocks.

### Example project

You can find a sample project [using `fancy_fences` here](https://github.com/pnezis/fancy_fences_example).

## Installation

In order to install the package add the following to your `mix.exs`:

```elixir
def deps do
  [
    {:fancy_fences, "~> 0.2.0", only: :dev, runtime: false}
  ]
end
```

and configure your fence processors accoring to the [docs](https://hexdocs.pm/fancy_fences).

## License

Copyright (c) 2023 Panagiotis Nezis

Tucan is released under the MIT License. See the [LICENSE](LICENSE) file for more
details.
