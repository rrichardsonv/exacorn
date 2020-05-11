defmodule ExAcorn.ShuntOnEm do
    @moduledoc """
    Shunting yard algorithm as explained at https://en.wikipedia.org/wiki/Shunting-yard_algorithm

    Refactored and repurposed from https://gist.github.com/pixyj/73bebd14be17ce680e9219f642044964

    For use, primarily in traversing tokens produced by the wonderful nimbleparsec
    ## Examples
    ```
    iex> tokens = [
        {:left, [val: "(", rank: 21]},
        {:num, [val: "3"]},
        {:op, [val: "*", rank: 15, key: :binary_expression]},
        {:num, [val: "2"]},
        {:op, [val: "+", rank: 14, key: :binary_expression]},
        {:num, [val: "5"]},
        {:right, [val: ")", rank: 21]},
        {:op, [val: "*", rank: 15, key: :binary_expression]},
        {:num, [val: "4"]},
    ]
    iex> tokens |> ShuntingYard.parse()
    [
        binary_expression: [
            operator: "*",
            right: {:num, [val: "4"]},
            left: {:binary_expression,
            [
            operator: "+",
            right: {:num, [val: "5"]},
            left: {:binary_expression,
                [operator: "*", right: {:num, [val: "2"]}, left: {:num, [val: "3"]}]}
            ]}
        ]
    ]
    ```
    """

    @type token :: {atom(), Keyword.t()}

    @spec add_to_queue(token, [token()], integer()) :: [token()]
    defp add_to_queue(token, output_queue, _call_id) do
        output_queue ++ [token]
    end

    @spec has_parens?([token()]) :: boolean()
    defp has_parens?(stack) do
        Enum.any?(stack, fn
            {k, _} when k in [:left, :right] -> true
            _ -> false
        end)
    end

    @spec parse([token()]) :: [token()]
    def parse(tokens) do
        {_, output_queue, stack} = parse_impl(tokens, [], [])

        if has_parens?(stack) do
            raise "Mismatched parens error"
        end

        to_tree(output_queue, stack)
    end

    defp to_tree(queue, stack) do
      stack = Enum.map(stack, fn {k, props} -> {k, Keyword.delete(props, :rank)} end)
      queue = Enum.reverse(queue)
      do_to_tree(queue, stack)
    end

    defp do_to_tree(queue, []), do: queue
    defp do_to_tree([{child_token, _} = child | rest], [{next_node, _} = next | stack]) when next_node in [:right_bracket, :right_paren] and child_token != :seq do
      do_to_tree([format_op_token(next, [child]) | rest], stack)
    end
    defp do_to_tree(queue, [token | stack]) do
        _ = IO.inspect(token, label: "token")
        {children, rest} = Enum.split(queue, 2)
        do_to_tree([format_op_token(token, children) | rest], stack)
    end

    defp format_op_token({:right_bracket, props}, children) do
      add_children(:bracket_group, props, children)
    end

    defp format_op_token({:right_paren, props}, children) do
      add_children(:paren_group, props, children)
    end

    defp format_op_token({:seq, props}, children) do
      add_children(:seq, props, children)
    end

    defp format_op_token({:op, props}, children) do
        {token_key, props} = Keyword.pop(props, :key)

        token_props =
            Enum.reduce(props, [], fn
                {:val, val}, acc ->
                    [{:operator, val} | acc]
                {:rank, _}, acc ->
                    acc
                entry, acc ->
                    acc ++ [entry]
            end)

        add_children(token_key, token_props, children)
    end

    defp add_children(key, props, [{:seq, seq_props}]) when key in [:bracket_group, :paren_group] do
      {key, Keyword.take(seq_props, [:expressions]) ++ props}
    end

    defp add_children(:paren_group, _props, [expression]), do: {:paren_group, expression}

    defp add_children(:seq, _props, [first]), do: {:seq, [expressions: [first, nil]]}
    defp add_children(:seq, _props, [left, {:seq, seq_props}]) do
      expressions = Keyword.fetch!(seq_props, :expressions)
      {:seq, [expressions: expressions ++ [left]]}
    end
    defp add_children(:seq, props, [first, second]), do: {:seq, [expressions: [first, second]] ++ props}
    defp add_children(:maybe_binary_expression, props, [right]), do: {:unary_expression, props ++ [right: maybe_ungroup(right)]}
    defp add_children(:maybe_binary_expression, props, [right, left]), do: {:binary_expression, props ++ [right: maybe_ungroup(right), left: maybe_ungroup(left)]}
    defp add_children(key, props, [right, left]), do: {key, props ++ [right: maybe_ungroup(right), left: maybe_ungroup(left)]}


    defp maybe_ungroup({:paren_group, [expression]}), do: expression
    defp maybe_ungroup(node), do: node

    @spec parse_impl([token()], [token()], [token()]) :: {[token()], [token()], [token()]}
    def parse_impl([], output_queue, stack), do: {[], output_queue, stack}
    def parse_impl([first | rest], output_queue, stack) do
        {output_queue, stack} = add_token(first, output_queue, stack)
        parse_impl(rest, output_queue, stack)
    end
# [1, 2, 2 - 2 * 3]
# queue | stack [
# queue 1| stack [
# queue 1| stack ,[
# queue 12 | stack ,[
# queue {:seq, 1,2}2 | stack ,[
# queue {:seq, 1,2}2 | stack -,[
# queue {:seq, 1,2}22 | stack -,[
# queue {:seq, 1,2}223 | stack *-,[
# queue {:seq, 1,2}223[ | stack *-,[
# queue {:seq, 1,2, {:op, -, 2, {:op, *, 2, 3}}} | stack *-,[


#   2 - 2 * 3

#   223 *-

    @spec add_token(token(), [token()], [token()]) :: {[token()], [token()]}
    def add_token({:right_paren, _} = token, output_queue, stack),
        do: {output_queue, [token | stack]}

    def add_token({:right_bracket, _} = token, output_queue, stack),
        do: {output_queue, [token | stack]}

    def add_token({:left_paren, _} = token, output_queue, stack),
        do: add_left_paren(token, output_queue, stack)

    def add_token({:left_bracket, _} = token, output_queue, stack),
        do: add_left_bracket(token, output_queue, stack)

    def add_token({:op, _} = token, output_queue, stack),
        do: add_operator(token, output_queue, stack)

    def add_token({:seq, _} = token, output_queue, stack),
        do: add_operator(token, output_queue, stack)

    def add_token(token, output_queue, stack),
        do: {add_to_queue(IO.inspect(token, label: "------------token"), output_queue, 1), stack}

    @spec add_left_paren(token(), [token()], [token()]) :: {[token()], [token()]}
    defp add_left_paren(_token, output_queue, stack) do
      case maybe_zipper_at(stack, :right_paren) do
        {inside, found, remaining} ->
          condensed_queue =
            output_queue
            |> to_tree(inside ++ [found])
            |> Enum.reverse()

          {condensed_queue, remaining}
        nil ->
          IO.inspect(output_queue, label: "queue")
          IO.inspect(stack, label: "stack")
          raise "Matching paren not found"
      end
    end

    @spec add_left_bracket(token(), [token()], [token()]) :: {[token()], [token()]}
    defp add_left_bracket(_token, output_queue, stack) do
      case maybe_zipper_at(stack, :right_bracket) do
        {inside, found, remaining} ->
          condensed_queue =
            output_queue
            |> to_tree(inside ++ [found])
            |> Enum.reverse()

          {condensed_queue, remaining}
        nil ->
          raise "Matching bracket not found"
      end
    end

    defp maybe_zipper_at([], _), do: nil
    defp maybe_zipper_at(stack, key) do
      zipper =
        Enum.split_while(stack, fn
          {^key, _} ->
            false
          _ ->
            true
        end)

      case zipper do
        {bef, [found | aft]} ->
          {bef, found, aft}
        {_, []} ->
          nil
      end
    end

    @spec add_operator(token(), [token()], [token()]) :: {[token()], [token()]}
    defp add_operator(token, output_queue, [{op_type, _} | _] = stack)
        when op_type in [:right_bracket, :right_paren] do

        {output_queue, [token | stack]}
    end

    defp add_operator(token, output_queue, stack) do
        {partial_queue, s1} = pop_higher_precendence_ops_to_queue(token, [], stack)

        next_queue =
            output_queue
            |> to_tree(partial_queue)
            |> Enum.reverse()

        {next_queue, [token | s1]}
    end

    defp pop_higher_precendence_ops_to_queue(_token, q, []),
        do: {q, []}

    defp pop_higher_precendence_ops_to_queue(token, q, [{op_type, _} | _] = stack)
        when op_type in [:right_bracket, :right_paren] do
          {q ++ [token], stack}
        end

    defp pop_higher_precendence_ops_to_queue(token, q, [top_op | rest] = stack) do
        [token, top_op]
        |> Enum.map(fn {_, props} -> props end)
        |> Enum.map(&Keyword.fetch!(&1, :rank))
        |> case do
            [token_rank, top_rank] when token_rank <= top_rank ->
                pop_higher_precendence_ops_to_queue(token, q ++ [top_op], rest)
            _ ->
                {q, stack}
        end
    end
end
