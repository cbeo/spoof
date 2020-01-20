package;

import Sexpr.*;

typedef ReadError = {source: UnicodeString, position: Int, error: String};
typedef ReadResult = Result<ReadError, Sexpr>;

class Reader {

  /// STATIC VARIABLES

  inline static var LEFT_PAREN:Int = 40;
  inline static var RIGHT_PAREN:Int = 41;
  inline static var SPACE:Int = 32;
  inline static var HTAB:Int = 9;
  inline static var NEWLINE:Int = 10;
  inline static var RETURN:Int = 13;
  inline static var DOUBLE_QUOTE:Int = 34;
  inline static var SINGLE_QUOTE:Int = 39;
  inline static var BACKTICK:Int = 96;
  inline static var COMMA:Int = 44;
  inline static var BACKSLASH:Int = 92; // for escapes in strings.
  inline static var PERIOD:Int = 46;

  inline static var SYMBOL_NAME_CHARS :UnicodeString = "+=-*&^%$!@~?/<>";

  static function isWhitespace(char:Int): Bool {
    return switch (char) {
    case SPACE | NEWLINE | HTAB | RETURN: true;
    default: false;
    };
  }

  static function isAlpha(char:Int): Bool {
    return (char  >= 65 && char <= 90) || (char >= 97 && char <= 122);
  }

  static function isLegalSymbolChar(char:Int): Bool {
    if (isAlpha(char)) return true;
    for (ch in SYMBOL_NAME_CHARS) if (char == ch) return true;
    return false;
  }

  static function isClosingBracket(char:Int): Bool {
    return char == RIGHT_PAREN;
  }

  static function isNumericChar(char:Int): Bool {
    return char >= 48 && char <= 57;
  }

  /// INSTANCE VARIABLES

  var position:Int;
  var input:UnicodeString;

  var eof(get,never):Bool;
  function get_eof():Bool {
    return position >= input.length;
  }

  var current(get,never):Int;
  function get_current():Int {
    return input.charCodeAt(position);
  }

  var endOfTerm(get,never):Bool;
  function get_endOfTerm():Bool {
    return eof || isWhitespace(current) || isClosingBracket(current);
  }

  var openParens:Int = 0; // not using this for anything i guess....?
  var canReadComma:Bool = false;

  function dropWhitespace() {
    while (isWhitespace( current ))
      position++;
  }

  public function reset(newInput:String) {
    input = newInput;
    position = 0;
  }

  public function read(?newInput:String):ReadResult {
    if (newInput != null) reset(newInput);

    dropWhitespace();
    return if (eof) Err({source:input, position:position, error:"eof"})
      else switch (current) {
        case LEFT_PAREN: {
          openParens++;
          position++;    // consume the opening parens
          readCons();
        }
        case DOUBLE_QUOTE: readString();
        case SINGLE_QUOTE: readQuoted();
        case BACKTICK: readQuasiquote();
        case COMMA: readComma();
        case num if (isNumericChar(num)): readNumber();
        case symb if (isLegalSymbolChar(symb)): readSymbol();
        default: Err({source:input, position:position, error:"parse failed"});
        };
  }

  function readQuoted(): ReadResult {
    position++; // consume the quote
    return read().then(quoted -> Ok(Cons(Atom(Sym("QUOTE")), quoted)));
  }

  function readQuasiquote(): ReadResult {
    position++; // consume the quasiquote
    canReadComma = true;
    return read().then(quoted -> Ok(Cons(Atom(Sym("#QUASIQUOTE")), quoted)));
  }

  function readComma(): ReadResult {
    position++;
    return if (canReadComma)
      read()
        .onOk(ignore -> canReadComma = false)
        .then(expr -> Ok(Cons(Atom(Sym("#UNQUOTE")), expr)))
      else
        Err({source:input,
              position:position,
              error: "Comma not within a quasiquote"});
  }

  function readCons():ReadResult {

    dropWhitespace();

    if (current == RIGHT_PAREN) {
      openParens--;
      position++;
      return Ok(Atom(Nil));
    }

    return read()
      .then(head -> readCons().map(tail -> Cons(head,tail)));
  }

  function readString():ReadResult {
    position++; // consume the opening " symbol
    var startPos = position;
    var escape = false;
    while (escape || current != DOUBLE_QUOTE) {
      escape = !escape && current == BACKSLASH;
      position++;
    }
    var str:UnicodeString = input.substring(startPos,position);
    position++; // consume the closing " symbol
    return Ok(Atom(Str(str)));
  }

  function readNumber():ReadResult {

    var startPos = position;
    var isFloat = false;

    while ( isNumericChar( current ))
      position++;

    if (current == PERIOD) {
      isFloat = true;
      position++;

      while ( isNumericChar( current ))
        position++;
    }

    // once we're done collecting digits, check that the next character is a
    // whitespace or some kind of ending bracket. I.e. like the ')' in '(1 2 3)'
    if ( endOfTerm ) {
      // if everythign checks out, stringify our buffer and parse.
      var str = input.substring(startPos, position);

      return if (isFloat) Ok(Atom(R(Std.parseFloat(str))))
        else Ok(Atom(Z(Std.parseInt(str))));

    } else {
      // otherwise, return an error
      return Err({source:input, position:position, error: "malformed number"});
    }

  }

  function readSymbol():ReadResult {
    // the way readSymbol() is called in read(), the first character should be a
    // valid non-numeric symbol character.
    var startPos = position;
    position++;
    while (isLegalSymbolChar( current ) || isNumericChar( current ))
      position++;
    if ( endOfTerm ) {
      var symb = (input.substring(startPos, position) : String).toUpperCase();
      return Ok(Atom(Sym(symb)));
    } else {
      return Err({source:input, position:position, error: "malformed symbol"});
    }
  }


  public function new(source: UnicodeString, ?pos:Int = 0) {
    input = source;
    position = pos;
  }


}