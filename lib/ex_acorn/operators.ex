defmodule ExAcorn.Operators do
  import NimbleParsec
  import ExAcorn.Utils

  def unary_operator,
    do:
      choice([
        string("-"),
        string("+"),
        string("!"),
        string("~"),
        string("typeof"),
        string("void"),
        string("delete")
      ])
      |> tag(:unary_operator)

  def binary_operator,
    do:
      lookahead(non_whitespace_chars())
      |> optional(space_chars())
      |> choice([
        string("==="),
        string("!=="),
        string(">>>"),
        string(">>"),
        string(">"),
        string("<<"),
        string("<"),
        string("<="),
        string(">="),
        string("*"),
        string("/"),
        string("%"),
        string("|"),
        string("^"),
        string("+"),
        string("-"),
        string("&"),
        string("in"),
        string("instanceof")
      ])
      |> tag(:binary_operator)

  def assignment_operator do
    lookahead(non_whitespace_chars())
    |> optional(space_chars())
    |> choice([
      string("="),
      string("+="),
      string("-="),
      string("*="),
      string("/="),
      string("%="),
      string("<<="),
      string(">>="),
      string(">>>="),
      string("|="),
      string("^="),
      string("&=")
    ])
  end
end
