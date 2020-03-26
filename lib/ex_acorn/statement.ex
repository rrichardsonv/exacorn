defmodule ExAcorn.Statement do
  import NimbleParsec

  # utils
  # |> tag(:incr_line)
  eol = ascii_char([?\n]) |> ignore()
  # |> ignore()
  whitespace = ascii_string([?\s, ?\t], min: 1) |> ignore()

  # edgecases
  empty_line = optional(whitespace) |> concat(eol)
  eom = choice([empty_line, eos()])

  # tokens
  empty_statement =
    optional(whitespace) |> concat(string(";")) |> lookahead(eom) |> tag(:empty_statement)

  defparsec(:parse, repeat(empty_line) |> concat(empty_statement))
end
