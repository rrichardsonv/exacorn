defmodule ExAcorn.Statement.EmptyStatement do
  import NimbleParsec

  alias ESTree.Tools.Builder, as: JST
  alias ESTree.EmptyStatement
  alias ESTree.SourceLocation
  alias ESTree.Position

  whitespace = ascii_string([?\s, ?\t, ?\n], min: 1) |> ignore()
  semi = optional(whitespace) |> string(";") |> tag(:semi)
  empty_statement = semi |> tag(:empty_statement)

  defparsec(:do_parse, empty_statement)

  def parse(js) do
    with {:ok, tokens, rem_js, state, position, match_size} <- do_parse(js),
         {:ok, %EmptyStatement{} = part_statement, opts} <-
           parse_tokens(tokens, state, position, match_size),
         {:ok, %EmptyStatement{} = statement} <- put_source_location(part_statement, opts) do
      {:ok, statement, rem_js}
    end
  end

  defp parse_tokens(tokens, state, pos, size) when is_list(tokens) do
    case Keyword.fetch(tokens, :empty_statement) do
      {:ok, empty_statement} ->
        source =
          empty_statement
          |> List.wrap()
          |> Enum.join()

        {:ok, JST.empty_statement(), to_opts(state, pos, size, source)}

      :error ->
        {:unparsed, tokens, to_opts(state, pos, size)}
    end
  end

  defp put_source_location(statement, opts) when is_list(opts) do
    with {:ok, source} <- Keyword.fetch(opts, :source),
         {:ok, %Position{} = start} <- fetch_start_pos(opts),
         {:ok, %Position{} = the_end} <- fetch_end_pos(opts),
         %SourceLocation{} = loc <- JST.source_location(source, start, the_end) do
      {:ok, %{statement | loc: loc}}
    end
  end

  defp to_opts(state, position, match_size, source \\ nil)

  defp to_opts(state, position, match_size, source),
    do: [state: state, position: position, match_size: match_size, source: source]

  defp fetch_start_pos(_opts), do: {:ok, %Position{}}
  defp fetch_end_pos(_opts), do: {:ok, %Position{}}
end
