defmodule FancyFences.MixProject do
  use Mix.Project

  @scm_url "https://github.com/pnezis/fancy_fences"
  @version "0.2.0"

  def project do
    [
      app: :fancy_fences,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      source_url: @scm_url,
      deps: deps(),
      docs: docs(),
      description: "Post-process code blocks in your markdown docs",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.29"}
    ]
  end

  defp package do
    [
      maintainers: ["Panagiotis Nezis"],
      licenses: ["MIT"],
      links: %{"GitHub" => @scm_url}
    ]
  end

  defp docs do
    [
      canonical: "http://hexdocs.pm/fancy_fences",
      source_url_pattern: "#{@scm_url}/blob/v#{@version}/%{path}#L%{line}",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      markdown_processor: {FancyFences, [fences: fence_processors()]},
      extras: [
        {:"README.md", title: "Overview"},
        "CHANGELOG.md",
        "LICENSE"
      ]
    ]
  end

  defp fence_processors do
    %{
      "fence-processor" => {FancyFences.Processors, :fence_processor_doc, []}
    }
  end
end
