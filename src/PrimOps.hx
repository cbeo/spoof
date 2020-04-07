package;

class PrimOps {
    public static function plus(a:Atomic, b:Atomic):Atomic {
        return switch ([a,b]) {
            case [Z(i),Z(j)]: Z(i+j);
            case [Z(i),R(f)]: R(i+f);
            case [R(f),Z(i)]: R(f+i);
            case [R(f),R(g)]: R(f+g);
            default: throw "Error, cannot add non numeric values";
        };
    }

    public static function mult(a:Atomic, b:Atomic):Atomic {
        return switch ([a,b]) {
            case [Z(i), Z(j)]: Z(i*j);
            case [Z(i), R(f)]: R(i*f);
            case [R(f),Z(i)]: R(i*f);
            case [R(f),R(g)]: R(f*g);
            default: throw "Error, cannot multiply non-numeric values";
        };
    }

    public static function minus(a:Atomic, b:Atomic):Atomic {
        return switch ([a,b]) {
            case [Z(i),Z(j)]: Z(i-j);
            case [Z(i),R(f)]: R(i-f);
            case [R(f),Z(i)]: R(f-i);
            case [R(f),R(g)]: R(f-g);
            default: throw "Error, cannot add non numeric values";
        };
    }
    
    public static function negate(a:Atomic):Atomic {
        return switch (a) {
            case Z(i): Z(-1 * i);
            case R(i): R(-1 * i);
            default: throw "Error, cannot negate nun numeric value";
        };
    }
    
    public static function isNumber(a:Atomic):Bool {
        return Sexpr.Atom(a).isNumber();
    }

}
