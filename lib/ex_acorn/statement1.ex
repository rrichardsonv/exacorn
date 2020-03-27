defmodule ExAcorn.Statement1 do
  import NimbleParsec

  # utils
  eol = ascii_char([?\n]) |> ignore()
  whitespace = ascii_string([?\s, ?\t], min: 1) |> ignore()
  rest_value = ascii_string([10..255], min: 1) |> eos() |> tag(:rest_value)
  non_block_rest_value = ascii_string([10..124, 126..255], min: 1) |> tag(:rest_value)
  rest_value_inner = ascii_string([10..255], min: 1) |> tag(:rest_value)

  open_brace = optional(whitespace) |> string("{") |> tag(:open_brace)
  close_brace = optional(whitespace) |> string("}") |> tag(:close_brace)
  semi = optional(whitespace) |> string(";") |> tag(:semi)

  # edgecases
  empty_line = optional(whitespace) |> concat(eol)

  # tokens
  empty_statement = semi |> tag(:empty_statement)

  block_statement =
    open_brace
    |> repeat(empty_line)
    |> concat(close_brace)
    |> tag(:block_statement)

  block_statement_with_content =
    open_brace
    |> concat(non_block_rest_value)
    |> optional(eol)
    |> optional(whitespace)
    |> concat(close_brace)
    |> tag(:block_statement)

  defparsecp(
    :parse_statement,
    repeat(empty_line)
    |> choice([
      empty_statement,
      block_statement_with_content,
      block_statement
    ])
    |> repeat(empty_line)
    |> choice([rest_value, eos()])
  )

  def parse(js) do
    with {:ok, tokens, rem_js, state, position, match_size} <- parse_statement(js),
         tokens <- maybe_inner_parse(tokens) do
      {:ok, tokens, rem_js, state, position, match_size}
    end
  end

  defp maybe_inner_parse(tokens) do
    Enum.reduce(tokens, [], fn
      {:block_statement, [_ | [_ | [_ | _]]] = inner_content}, acc ->
        parsed_content = do_parse(Keyword.drop(inner_content, [:open_brace, :close_brace]))

        [
          {:block_statement, [{:open_brace, ["{"]}, parsed_content, {:close_brace, ["}"]}]}
          | acc
        ]

      item, acc ->
        [item | acc]
    end)
  end

  defp do_parse(rest_value: rest_value) do
    {:ok, parsed_content, _, _, position, match_size} = parse(Enum.join(rest_value))
    {:children, {parsed_content, position, match_size}}
  end
end
