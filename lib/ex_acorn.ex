defmodule ExAcorn do
  @moduledoc false

  alias ESTree.Tools.Builder, as: JBuild
  alias ESTree.SourceLocation
  alias ESTree.Position
  alias ExAcorn.Statement

  def parse(js) do
    {body, {loc_end, loc_source}} = do_parse_top(js, 1, 0, "", [])

    location = JBuild.source_location(loc_source, JBuild.position(1, 0), loc_end)

    JBuild.program(body, :module, location)
  end

  defp do_parse_top("", line, col, source, acc), do: {acc, do_parse_loc(line, col, source)}

  defp do_parse_top(js, line, col, source, acc) when is_binary(js) do
    {rem_js, statement, next_source} = parse_statement(js, line, col, source)

    do_parse_top(rem_js, end_line(statement), end_col(statement), next_source, [
      statement | acc
    ])
  end

  defp end_line(%{loc: %SourceLocation{end: %Position{line: line}}}), do: line
  defp end_col(%{loc: %SourceLocation{end: %Position{column: col}}}), do: col

  defp parse_statement(js, line, col, source) do
    with {:ok, tokens, rem_js, _, {end_line, end_col}, _size} <-
           IO.inspect(Statement.parse(js), label: "---------"),
         {:ok, rem_text, token_map} <- format_tokens(tokens),
         {:ok, statement, statement_source} <-
           do_parse_statement(token_map, {line, col}, {end_line, end_col + 1}) do
      {rem_text <> rem_js, statement, source <> statement_source}
    end
  end

  defp do_parse_statement(%{empty_statement: source}, start_coord, end_coord)
       when is_list(source) do
    binary_source = Enum.join(source)
    location = to_loc(binary_source, start_coord, end_coord)
    {:ok, JBuild.empty_statement(location), binary_source}
  end

  defp to_pos({l, c}), do: JBuild.position(l, c)

  defp to_loc(source, {_, _} = start_coord, {_, _} = end_coord),
    do: apply(JBuild, :source_location, [source | Enum.map([start_coord, end_coord], &to_pos/1)])

  # defp do_parse_statement(";" <> js, line, col, _source),
  #   do: {JBuild.empty_statement(), {JBuild.position(line, col + 1), ";"}, js}

  defp do_parse_loc(line, col, loc_source) do
    loc_end = JBuild.position(line, col)
    {loc_end, loc_source}
  end

  defp format_tokens(tokens),
    do:
      {:ok, Keyword.get(tokens, :rest_value, ""),
       Keyword.delete(tokens, :rest_value) |> Map.new()}
end
