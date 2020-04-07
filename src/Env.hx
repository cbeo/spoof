package;


class Env<T> {

    var parent:Env<T>;
    var bindings:Bindings<T>; 


    public function extend(bs:Bindings<T>):Env<T> {
        return new Env(bs, this);
    }

    public function lookup(name:UnicodeString):Option<T> {
        var val = this.bindings.get(name);
        if (val != null) return Some(val);
        if (parent != null) return parent.lookup(name);
       return None;
    }

    public function update(name:UnicodeString, val:T, ?insert = false): Option<{}> {
        if (this.bindings.exists(name) || insert) {
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
