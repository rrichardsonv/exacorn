defmodule ExAcorn.Operators do
  import NimbleParsec
  import ExAcorn.Utils

  def operator,
    do:
      optional(space_chars())
      |> choice([
        string("===") |> tag(:binary_operator),
        string("!==") |> tag(:binary_operator),
        string(">>>") |> tag(:binary_operator),
        string(">>>=") |> tag(:assignment_operator),
        string("<<=") |> tag(:assignment_operator),
        string(">>=") |> tag(:assignment_operator),
        string(">>") |> tag(:binary_operator),
        string("<<") |> tag(:binary_operator),
        string("<=") |> tag(:binary_operator),
        string(">=") |> tag(:binary_operator),
        string("in") |> concat(whitespace()) |> tag(:binary_operator),
        string("instanceof") |> concat(whitespace()) |> tag(:binary_operator),
        string("typeof") |> concat(whitespace()) |> tag(:unary_operator),
        string("void") |> concat(whitespace()) |> tag(:unary_operator),
        string("delete") |> concat(whitespace()) |> tag(:unary_operator),
        string("+=") |> tag(:assignment_operator),
        string("-=") |> tag(:assignment_operator),
        string("*=") |> tag(:assignment_operator),
        string("/=") |> tag(:assignment_operator),
        string("%=") |> tag(:assignment_operator),
        string("|=") |> tag(:assignment_operator),
        string("^=") |> tag(:assignment_operator),
        string("&=") |> tag(:assignment_operator),
        string("||") |> tag(:logical_operator),
        string("&&") |> tag(:logical_operator),
        string("--") |> tag(:update_operator),
        string("++") |> tag(:update_operator),
        string("-") |> tag(:unary_operator),
        string(">") |> tag(:binary_operator),
        string("<") |> tag(:binary_operator),
        string("*") |> tag(:binary_operator),
        string("/") |> tag(:binary_operator),
        string("%") |> tag(:binary_operator),
        string("|") |> tag(:binary_operator),
        string("^") |> tag(:binary_operator),
        string("&") |> tag(:binary_operator),
        string("+") |> tag(:unary_operator),
        string("!") |> tag(:unary_operator),
        string("~") |> tag(:unary_operator),
        string("=") |> tag(:assignment_operator)
      ])
end
