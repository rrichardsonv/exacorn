defmodule ExAcorn do
  @moduledoc false

  alias ESTree.Tools.Builder, as: JBuild

  def parse(js) do
    {body, {loc_end, loc_source}} = do_parse_top(js, 1, 0, "", [])

    location = JBuild.source_location(loc_source, JBuild.position(1, 0), loc_end)

    JBuild.program(body, :module, location)
  end

  defp do_parse_top("", line, col, source, acc), do: {acc, do_parse_loc(line, col, source)}

  defp do_parse_top(js, line, col, source, acc) when is_binary(js) do
    {remaining_js, statement, {next_line, next_col}, source} =
      parse_statement(js, line, col, source)

    do_parse_top(remaining_js, next_line, next_col, source, [statement | acc])
  end

  defp parse_statement(js, line, col, source) do
    {statement, {loc_end, loc_source}, rem_js} = do_parse_statement(js, line, col, "")
    location = JBuild.source_location(loc_source, JBuild.position(line, col), loc_end)

    {
      rem_js,
      struct!(statement, loc: location),
      {loc_end.line, loc_end.column},
      source <> loc_source
    }
  end

  defp do_parse_statement(";" <> js, line, col, _source),
    do: {JBuild.empty_statement(), {JBuild.position(line, col + 1), ";"}, js}

  defp do_parse_loc(line, col, loc_source) do
    loc_end = JBuild.position(line, col)
    {loc_end, loc_source}
  end
end
