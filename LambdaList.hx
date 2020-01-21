package;

import Sexpr.*;

class LambdaList {

  var structure:Sexpr;

  // TODO: handle &OPTION and &KEY arguments
  public function bind(vals: Sexpr): Option<Map<String, Sexpr>> {

    var vals = vals;
    var lambdaList = structure;
    var bindings = new Map();

    while (true) switch ([lambdaList, vals]) {
      case [Atom(Nil), Atom(Nil)]:
        return Some(bindings);

      case [Cons(Atom(Sym("&REST")), Cons(Atom(Sym(name)), _)), vals]: {
        bindings[name] = vals;
        return Some(bindings);
      }

      case [Cons(Atom(Sym(name)), llTail), Cons(head, valsTail)]: {
        bindings[name] = head;
        vals = valsTail;
        lambdaList = llTail;
      }

      default:
        return None;
      }
  }

  public function new(ll: Sexpr) {
    this.structure = ll;
  }
}