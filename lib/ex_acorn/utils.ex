defmodule ExAcorn.Utils do
  import NimbleParsec

  # utils
  defcombinatorp(
    :util_whitespace,
    ascii_string([?\s, ?\t, ?\n, ?\r], min: 1) |> ignore() |> label("whitespace")
  )

  def whitespace,
    do: ascii_string([?\s, ?\t, ?\n, ?\r], min: 1) |> ignore() |> label("whitespace")

  defcombinatorp(
    :util_space_chars,
    ascii_string([?\s, ?\t], min: 1) |> ignore() |> label("space_chars")
  )

  def space_chars, do: ascii_string([?\s, ?\t], min: 1) |> ignore() |> label("space_chars")

  defcombinatorp(:util_eol, ascii_char([?\n]) |> ignore() |> label("eol"))
  def eol, do: ascii_char([?\n]) |> ignore() |> label("eol")

  defcombinatorp(:util_semi, ascii_char([?;]) |> ignore() |> label("semi"))
  def semi, do: ascii_char([?;]) |> ignore() |> label("semi")

  defcombinatorp(:util_period, ascii_char([?.]) |> label("period"))
  def period, do: ascii_char([?.]) |> label("period")

  defcombinatorp(:util_colon, ascii_char([?:]) |> label("colon"))
  def colon, do: ascii_char([?:]) |> label("colon")

  defcombinatorp(:util_comma, ascii_char([?,]) |> label("comma"))
  def comma, do: ascii_char([?,]) |> label("comma")

  defcombinatorp(:util_open_curly, ascii_char([?{]) |> label("open_curly"))
  def open_curly, do: ascii_char([?{]) |> label("open_curly")

  defcombinatorp(:util_close_curly, ascii_char([?}]) |> label("close_curly"))
  def close_curly, do: ascii_char([?}]) |> label("close_curly")

  defcombinatorp(:util_open_brace, ascii_char([?{]) |> tag(:open_brace))
  def open_brace, do: ascii_char([?{]) |> tag(:open_brace)

  defcombinatorp(:util_close_brace, ascii_char([?}]) |> tag(:close_brace))
  def close_brace, do: ascii_char([?}]) |> tag(:close_brace)

  defcombinatorp(:util_double_quote, ascii_char([?"]) |> ignore() |> label("double_quote"))
  def double_quote, do: ascii_char([?"]) |> ignore() |> label("double_quote")

  defcombinatorp(:util_single_quote, ascii_char([?']) |> ignore() |> label("single_quote"))
  def single_quote, do: ascii_char([?']) |> ignore() |> label("single_quote")

  defcombinatorp(:util_backtick_quote, ascii_char([?`]) |> ignore() |> label("backtick_quote"))
  def backtick_quote, do: ascii_char([?`]) |> ignore() |> label("backtick_quote")

  defcombinatorp(:util_open_paren, ascii_char([?(]) |> ignore() |> label("open_paren"))
  def open_paren, do: ascii_char([?(]) |> ignore() |> label("open_paren")

  defcombinatorp(:util_close_paren, ascii_char([?)]) |> ignore() |> label("close_paren"))
  def close_paren, do: ascii_char([?)]) |> ignore() |> label("close_paren")

  defcombinatorp(
    :util_non_whitespace_chars,
    ascii_string([not: ?\s, not: ?\t, not: ?\n, not: ?\r], min: 1) |> label("non_whitespace")
  )

  def non_whitespace_chars,
    do: ascii_string([not: ?\s, not: ?\t, not: ?\n, not: ?\r], min: 1) |> label("non_whitespace")

  defcombinatorp(
    :util_expression_boundary,
    choice([parsec(:util_eol), parsec(:util_semi) |> concat(parsec(:util_eol))])
    |> ignore()
    |> label("expression_boundary")
  )

  def expression_boundary,
    do:
      choice([
        ascii_char([?\n, ?\r]) |> ignore() |> label("eol"),
        ascii_char([?;]) |> optional(ascii_char([?\n])) |> ignore() |> label("semi")
      ])
      |> ignore()
      |> label("expression_boundary")

  defcombinatorp(:util_eq, ascii_char([?=]) |> tag(:eq))
  def eq, do: ascii_char([?=]) |> tag(:eq)

  defcombinatorp(:util_question_mark, ascii_char([??]) |> tag(:question_mark))
  def question_mark, do: ascii_char([??]) |> tag(:question_mark)

  def non_control_char,
    do:
      ascii_string(
        [
          10..255,
          {:not, ?"},
          {:not, ?'},
          {:not, ?`},
          {:not, ?,},
          {:not, ?;},
          {:not, ?}},
          {:not, ?{},
          {:not, ?(},
          {:not, ?)},
          {:not, ?:},
          {:not, ??},
          {:not, ?.},
          {:not, ?=},
          {:not, ?\n},
          {:not, ?\r}
        ],
        min: 1
      )
      |> tag(:non_control_char)

  def line_text do
    ascii_char([?$, ?_, ?a..?z, ?A..?Z])
    |> optional(ascii_string([?$, ?_, ?a..?z, ?A..?Z, ?0..?9], min: 1))
    |> reduce({__MODULE__, :mixed_binary_to_string, []})
    |> label("line_text")
  end

  def mixed_binary_to_string([char | _] = line_text) when is_integer(char),
    do: List.to_string(line_text)

  def mixed_binary_to_string([char, rest]) when is_integer(char),
    do: List.to_string([char]) <> rest

  def optional_whitespace_wrap(combinator, opts \\ []) when is_list(opts) do
    opts
    |> Keyword.take([:pre, :post])
    |> Map.new()
    |> do_whitespace_wrap(combinator)
  end

  defp do_whitespace_wrap(config, combinator) when is_map(config) do
    local_whitespace =
      ascii_string([?\s, ?\t, ?\n, ?\r], min: 1)
      |> ignore()
      |> optional()
      |> label("whitespace")

    {pre_combinator, post_combinator} =
      Enum.reduce(
        config,
        {local_whitespace, local_whitespace},
        &get_combinator/2
      )

    pre_combinator
    |> concat(combinator)
    |> concat(post_combinator)
  end

  defp get_combinator({:pre, :eol}, {_pre, post}),
    do: {optional(ignore(ascii_char([?\n, ?\r])) |> label("eol")), post}

  defp get_combinator({:pre, :space_char}, {_pre, post}),
    do: {optional(ignore(ascii_string([?\s, ?\t], min: 1)) |> label("space_chars")), post}

  defp get_combinator({:post, :eol}, {pre, _post}),
    do: {pre, optional(ignore(ascii_char([?\n, ?\r])) |> label("eol"))}

  defp get_combinator({:post, :space_char}, {pre, _post}),
    do: {pre, optional(ignore(ascii_string([?\s, ?\t], min: 1)) |> label("space_chars"))}

  defp get_combinator(_, acc), do: acc
end
