defmodule ExAcorn.Statement.SwitchStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def switch_statement(expression \\ empty(), root_combinator \\ empty()) do
    case_kw = ignore(string("case")) |> label("switch - case")
    default_kw = ignore(string("default")) |> label("switch - default")
    case_begin = ignore(colon()) |> label("switch - colon")

    discriminant = paren_group([expression]) |> unwrap_and_tag(:discriminant)

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
          root_combinator
        ])
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
              ignore(whitespace()),
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
    |> concat(discriminant)
    |> optional(whitespace())
    |> concat(curly_group([switch_case, empty_switch_case]))
    |> tag(:cases)
    |> tag(:switch_statement)
  end
end
