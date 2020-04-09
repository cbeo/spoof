package spoof;

typedef KVPair<T> = {name:UnicodeString, value: T};

class PairBindings<T> {
  var pairs:Array<KVPair<T>>;

  function getPair(name:UnicodeString):Null<KVPair<T>> {
    for (p in pairs)
      if (p.name == name)
        return p;
    return null;
  }

  public function exists(name:UnicodeString):Bool {
    return getPair(name) != null;
  }

  public function get(name):Null<T> {
    var pair = getPair(name);
    return if (pair != null) pair.value else null;
  }

  public function set(name,value) {
    var pair = getPair(name);
    if (pair == null)
      pairs.push({name:name, value:value});
    else
      pair.value = value;
  }

  public function new () {
    pairs = [];
  }
}
