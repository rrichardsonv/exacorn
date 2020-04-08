defmodule ExAcorn.Statement.ClassStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def class_statement(root_statement \\ empty()) do
    maybe_namespaced_line_text =
      repeat(
        lookahead_not(whitespace())
        |> concat(line_text())
        |> optional(ignore(ascii_char([?.])))
      )

    extends_clause =
      ignore(string("extends"))
      |> concat(whitespace())
      |> concat(maybe_namespaced_line_text |> tag(:extends))

    ignore(string("class"))
    |> concat(whitespace())
    |> concat(maybe_namespaced_line_text |> tag(:classname))
    |> optional(whitespace() |> concat(extends_clause))
    |> optional(whitespace())
    |> concat(local_block(root_statement))
    |> tag(:class_statement)
  end
end
