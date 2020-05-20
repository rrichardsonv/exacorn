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
        break
      }
      log('(for future refrence;) i', `= + ${i}` + ", j = " + j)
    }
    }
    """

    assert :foo == S.parse(js)
  end

  test "while" do
    js = """

    var foo = -1
    let res = 0, bar = [1,2,3]

    while (foo < 10) {
      res + 2
    }

    do {
      console.log(baz[res]);
      res = function(x){
       x - 2
      };
    } while(res>=0)
    """

    assert :foo == S.parse(js)
  end

  test "params" do
    js = """
    function b(a, b, ...c) {
      async function do_the_thing({abc: def = 1}) {
        console.log(def);
      }

      return do_the_thing(c.forEach(foo => foo + a + b));
    }
    """

    assert :foo == S.parse(js)
  end

  test "class declaration" do
    js = """
    class Foo extends React.Component {
      render(){
        return null;
      }
    }

    export default class Foo extends React.Component {
      render(){
        return null;
      }
    }
    """

    assert :foo == S.parse(js)
  end

  test "switch gud" do
    js2 = """
    const expr = 'Papayas';
    switch (expr) {
    default:console.log('Sorry, we are out of ' + expr + '.');case'Oranges': console.log('Oranges are $0.59 a pound.');break; case 'Mangoes' :case
    'Papayas' /*
        I dunno some shit
        New {:} who dis
      */:console.log('Mangoes and papayas are $2.79 a pound.'); // expected output: "Mangoes and papayas are $2.79 a pound."
    break;
    }
    """

    js1 = """
    const expr = 'Papayas';
    switch (expr) {
      default:
        console.log('Sorry, we are out of ' + expr + '.');
      case 'Oranges':
        console.log('Oranges are $0.59 a pound.');
        break;
      case 'Mangoes':
      case 'Papayas' /*
        I dunno some shit
        New {:} who dis
      */:
        console.log('Mangoes and papayas are $2.79 a pound.');// expected output: "Mangoes and papayas are $2.79 a pound."
        break;
    }
    """

    {:ok, tree1, _, _, _, _} = S.parse(js1)
    {:ok, tree2, _, _, _, _} = S.parse(js2)

    assert :ok == tree2
    assert tree1 == tree2
  end

  test "switch inside switch" do
    js1 = """
    const expr = 'Papayas';
    var b = 0;
    switch (expr) {
      case 'Oranges':
        console.log('Oranges are $0.59 a pound.');
        switch (true) {
          case b > -1:
            return 'a';
          case b > -1:
            return 'b';
          default:
            throw new Error('c');
        }
        break;
      default:
        console.log('Sorry, we are out of ' + expr + '.');
    }
    """

    assert :ok == S.parse(js1)
  end


  test "literal nonsense" do
    js = """
    var re = /[^@]+@[^@]+/g
    const maybeEmails = [
      "foo.bar@example.com",
      "jojo@bizzaro.co.uk",
    ]

    const requests =
      maybeEmail.filter(me => re.test(me))
                .map(em => {
                  return fetch(process.env.API_URL + "/user", {email: em})
                })

    Promise.all(requests).then(users => {
      if(!users.length) return null;

      return hydrate(users, false);
    })
    .catch((err) => {
      console.error(err);
      throw new RequestError(err);
    })
    """

    assert :ok == S.parse(js)
  end

  test "ternary" do
    js = """
    var foo = true;
    const bar = foo ? false : true
    let z = () => bar ? foo : !bar

    function y (x) {
      return x() ? "y" : "z"
    }

    y(z)
    """
    assert :ok == S.parse(js)
  end

  test "operator precedence" do
    js = """
    var a = (2 - 2) + 4 * 3
    var b = 3 * 2 - 2

    var c = 1,d = 2,e;
    const c, d = 1,e = 2,f;

    let both = c = 2 - 2;
    """
    assert :ok == S.parse(js)
  end
end
