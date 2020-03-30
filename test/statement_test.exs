defmodule ExAcorn.StatementTest do
  use ExUnit.Case
  alias ExAcorn.Statement, as: S

  test "foo bar baz" do
    js = """
    var i, j;
    /*
    usage:
    function* do_the_thing(x, y) {
      // "..."
    }
    do_the_thing(1, 2)
    */

    function log(...text) {
      console.log(...text);
    }

    function object_return() {
      return {
        bah: "humbug"
      }
    }

    function object_return(foo) {
      if(!foo) return null
      try {
       const state = {
          bah: "humbug"
        }
        return state
      } catch (e) {
        throw e
      }
    }

    loop1 : for (i = 0; i < 3; i++) {      //The first for statement is labeled "loop1"
    loop2:
    for (j = 0; j < 3; j++) {   //The second for statement is labeled "loop2"
      if (i === 1 && j === 1) {
         continue loop1;
      } else {
        break "banana";
      }
      log('(for future refrence;) i', `= + ${i}` + ", j = " + j)
    }
    }
    """

    assert :foo == S.parse(js)
  end
end
