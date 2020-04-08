defmodule ExAcorn.Statement.SwitchStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def switch_statement do
    case_kw = ignore(string("case")) |> label("switch - case")
    default_kw = ignore(string("default")) |> label("switch - default")
    case_begin = ignore(colon()) |> label("switch - colon")

    # case without consequent
    empty_switch_case =
      case_kw
      |> optional(whitespace())
      |> repeat(lookahead_not(case_begin) |> concat(ascii_string([not: ?:], min: 1)))
      |> optional(whitespace())
      |> concat(case_begin)
      |> lookahead(
        choice([
          case_kw,
          default_kw
        ])
      )
      |> tag(:consequent)

    # case with consequent or default
    switch_consequent =
      repeat(
        lookahead_not(
          choice([
            case_kw,
            default_kw,
            close_brace()
          ])
        )
        |> choice([
          ignore(space_chars()),
          quoted_string(),
          comment(),
          ascii_string([not: ?\n, not: ?;], min: 1)
        ])
        |> concat(expression_boundary())
        |> optional(space_chars())
      )
      |> tag(:consequent)

    # case with consequent, case without consequent, or default
    switch_case =
      choice([
        optional(space_chars())
        |> concat(case_kw)
        |> optional(whitespace())
        |> repeat(
          choice([
            optional(whitespace()) |> concat(quoted_string()),
            optional(whitespace()) |> concat(comment()),
            lookahead_not(case_begin)
            |> choice([
              ignore(eol()),
              ascii_string([not: ?:, not: ?\n], min: 1)
            ])
          ])
        )
        |> tag(:test),
        default_kw |> tag(:test)
      ])
      |> optional(whitespace())
      |> concat(case_begin)
      |> optional(whitespace())
      |> concat(switch_consequent)
      |> tag(:switch_case)

    ignore(string("switch"))
    |> optional(whitespace())
    |> concat(
      paren_group([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        variable_statement(),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
      |> tag(:discriminant)
    )
    |> optional(whitespace())
    |> concat(
      ignore(open_curly())
      |> optional(whitespace())
      |> repeat(
        lookahead_not(close_curly())
        |> optional(space_chars())
        |> choice([
          switch_case,
          empty_switch_case
        ])
        |> optional(whitespace())
      )
      |> tag(:cases)
    )
    |> optional(whitespace())
    |> ignore(close_brace())
    |> tag(:switch_statement)
  end
end
