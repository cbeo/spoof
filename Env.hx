package;


class Env<T> {

  var parent:Env<T>;
  var bindings:Bindings<T>; //Map<String,T>;


  public function extend(bs:Bindings<T>):Env<T> {
    return new Env(bs, this);
  }

  //public function lambdaListExtend(lambdaList: Sexpr, vals: Sexpr): Env<Sexpr>

  public function lookup(name:String):Option<T> {
    var val = this.bindings.get(name);
    if (val != null) return Some(val);
    if (parent != null) return parent.lookup(name);
    return None;
  }

  public function update(name:String, val:T): Option<{}> {
    if (this.bindings.exists(name)) {
      this.bindings.set(name,val);
      return Some({}); // succeeded
    }
    if (this.parent != null) return parent.update(name, val);
    return None;
  }

  public function new (bs:Bindings<T>, ?p:Env<T> = null) {
    this.bindings = bs;
    this.parent = p;
  }


}