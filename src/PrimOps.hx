package;

class PrimOps {
    public static function plus(a:Sexpr, b:Sexpr):Sexpr {
        return switch ([a,b]) {
            case [Z(i),Z(j)]: Z(i+j);
            case [Z(i),R(f)]: R(i+f);
            case [R(f),Z(i)]: R(f+i);
            case [R(f),R(g)]: R(f+g);
            default: throw "Error, cannot add non numeric values";
        };
    }

    public static function mult(a:Sexpr, b:Sexpr):Sexpr {
        return switch ([a,b]) {
            case [Z(i), Z(j)]: Z(i*j);
            case [Z(i), R(f)]: R(i*f);
            case [R(f),Z(i)]: R(i*f);
            case [R(f),R(g)]: R(f*g);
            default: throw "Error, cannot multiply non-numeric values";
        };
    }

    public static function minus(a:Sexpr, b:Sexpr):Sexpr {
        return switch ([a,b]) {
            case [Z(i),Z(j)]: Z(i-j);
            case [Z(i),R(f)]: R(i-f);
            case [R(f),Z(i)]: R(f-i);
            case [R(f),R(g)]: R(f-g);
            default: throw "Error, cannot add non numeric values";
        };
    }

}
