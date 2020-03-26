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
    with {:ok, tokens, rem_js, _, {end_line, end_col}, size} <-
           IO.inspect(Statement.parse(js), label: "---------"),
         {:ok, rem_text, token_map} <- format_tokens(tokens),
         {:ok, statement, statement_source} <-
           do_parse_statement(token_map, {line, col}, {end_line, end_col, size}) do
      {rem_text <> rem_js, statement, source <> statement_source}
    end
  end

  defp srt(a, b) when a > b, do: 1
  defp srt(a, b) when a < b, do: -1
  defp srt(a, b) when a == b, do: 0

  defp do_parse_statement(
         statement,
         {start_line, _start_col} = start_coord,
         {end_line, end_col, match_size}
       ) do
    case {srt(end_line, start_line), srt(match_size, end_col)} do
      {0, 1} ->
        do_parse_statement(statement, start_coord, {end_line, match_size})

      {1, 0} ->
        do_parse_statement(statement, start_coord, {end_line, 0})

      _ ->
        do_parse_statement(statement, start_coord, {end_line, end_col})
    end
  end

  defp do_parse_statement(%{empty_statement: _source}, start_coord, end_coord) do
    location = to_loc(";", start_coord, end_coord)
    {:ok, JBuild.empty_statement(location), ";"}
  end

  defp do_parse_statement(
         %{block_statement: [{:open_brace, _}, {:close_brace, _}]},
         start_coord,
         end_coord
       ) do
    location = to_loc("{}", start_coord, end_coord)
    {:ok, JBuild.block_statement([], location), "{}"}
  end

  defp do_parse_statement(
         %{
           block_statement: [
             {:open_brace, _},
             {:children, {statement_children, {cend_l, cend_c}, _child_match_size}},
             {:close_brace, _}
           ]
         },
         start_coord,
         end_coord
       ) do
    with {:ok, children, ch_source} <-
           do_parse_statement(
             Map.new(statement_children),
             start_coord,
             {cend_l, cend_c}
           ) do
      location = to_loc("{#{ch_source}}", start_coord, end_coord)
      {:ok, JBuild.block_statement(List.wrap(children), location), "{#{ch_source}}"}
    end
  end

  defp to_pos({l, c}), do: JBuild.position(l, c)

  defp to_loc(source, {_, _} = _start_coord, {_, _} = _end_coord),
    do: apply(JBuild, :source_location, [source | Enum.map([{1, 0}, {1, 0}], &to_pos/1)])

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
