defmodule ExAcorn.Statement do
  import NimbleParsec

  # utils
  # |> tag(:incr_line)
  eol = ascii_char([?\n]) |> ignore()
  # |> ignore()
  whitespace = ascii_string([?\s, ?\t], min: 1) |> ignore()
  rest_value = ascii_string([10..255], min: 1) |> eos() |> tag(:rest_value)

  # edgecases
  empty_line = optional(whitespace) |> concat(eol)

  # tokens
  empty_statement =
    optional(whitespace)
    |> string(";")
    |> tag(:empty_statement)

  defparsec(
    :parse,
    repeat(empty_line)
    |> concat(empty_statement)
    |> repeat(empty_line)
    |> choice([rest_value, eos()])
  )
end
