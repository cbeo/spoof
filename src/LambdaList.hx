package;

import Sexpr.*;

class LambdaList {

  public static function isValidExpression(sexpr:Sexpr):Bool {
    var valid = true;
    sexpr.foreach( val -> {
        switch (val) {
        case Nil | True | Sym("TRUE") | Sym("NIL"):
          valid = false;

        case expr:
          if (!expr.isSymbol())
            valid = false;
        }
      });
    return valid;
  }


  var structure:Sexpr;

  // TODO: handle &OPTION and &KEY arguments
  public function bind(vals: Sexpr): Option<PairBindings<Sexpr>> { //Option<Map<String, Sexpr>> {

    var vals = vals;
    var lambdaList = structure;
    var bindings = new PairBindings();

    while (true) switch ([lambdaList, vals]) {
      case [Nil, Nil]:
        return Some(bindings);

      case [Cons(Sym("&REST"), Cons(Sym(name), _)), vals]: {
        bindings.set(name,vals);
        return Some(bindings);
      }

      case [Cons(Sym(name), llTail), Cons(head, valsTail)]: {
        bindings.set(name,head);
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
