package;

import Sexpr.*;

typedef ReadError = {source: UnicodeString, position: Int, error: String};
typedef ReadResult = Result<ReadError, Sexpr>;

enum ReaderMacro {
  SingleFormMacro(fn:UnicodeString->Sexpr);
  StopCharacterMacro(stopChar: Int, fn:UnicodeString->Sexpr);
}

class Reader {

  /// STATIC VARIABLES

  inline static var LEFT_PAREN:Int = 40;
  inline static var RIGHT_PAREN:Int = 41;
  inline public static var SPACE:Int = 32;
  inline public static var HTAB:Int = 9;
  inline public static var NEWLINE:Int = 10;
  inline public static var RETURN:Int = 13;
  inline static var DOUBLE_QUOTE:Int = 34;
  inline static var SINGLE_QUOTE:Int = 39;
  inline static var BACKTICK:Int = 96;
  inline static var COMMA:Int = 44;
  inline static var BACKSLASH:Int = 92; // for escapes in strings.
  inline static var FORWARDSLASH:Int = 47;
  inline static var PERIOD:Int = 46;
  inline static var AT_SIGN:Int = 64;
  inline static var COLON:Int = 58;
  inline static var SEMICOLON:Int = 59;
  inline static var RIGHT_CURLY = 123;
  inline static var LEFT_CURLY = 125;
  inline static var OCTOTHORPE:Int = 0x23;

  inline static var SYMBOL_NAME_CHARS :UnicodeString = "+=-*&^%$!@~?/<>";

  static function isWhitespace(char:Int): Bool {
    return switch (char) {
    case SPACE | NEWLINE | HTAB | RETURN: true;
    default: false;
    };
  }

  static function isLineBreak(char:Int): Bool {
    return switch (char) {
    case NEWLINE | RETURN: true;
    default: false;
    }
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

  static function interperetAsChar(raw:UnicodeString): Sexpr {
    return switch (raw.toUpperCase()) {
    case "": Atom(Char(0)); // the null char.
    case "SPACE": Atom(Char(SPACE));
    case "NEWLINE": Atom(Char(NEWLINE));
    case "TAB": Atom(Char(HTAB));
    case "RETURN": Atom(Char(RETURN));
    case ch if(ch.length == 1): Atom(Char(raw.charCodeAt(0)));
    default: throw 'Cannot interperet $raw as a character';
    };
  }

  static function readRegularExpression(raw:UnicodeString): Sexpr {
    return Atom(Regex(new EReg(raw,""), raw));
  }

  /// INSTANCE VARIABLES

  var position:Int;
  public var input(default,null):UnicodeString;

  var readerMacros:Map<Int,ReaderMacro>;

  var eof(get,never):Bool;
  function get_eof():Bool {
    return position >= input.length;
  }

  var current(get,never):Null<Int>;
  function get_current():Null<Int> {
    return input.charCodeAt(position);
  }

  var endOfTerm(get,never):Bool;
  function get_endOfTerm():Bool {
    return eof || isWhitespace(current) || isClosingBracket(current);
  }

  var quasiquoteNesting:Int = 0;

  function dropWhitespace() {
    while (isWhitespace( current ))
      position++;
  }

  function dropLine() {
    while (!isLineBreak( current )) {
      position++;
    }
  }

  function dropUntil(char:Int, ?inclusive = false) {
    while(current != char) position++;
    if (inclusive) position++;
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
          position++;    // consume the opening parens
          readCons();
        }
        case SEMICOLON: {
          dropLine();
          read();
        }
        case COLON: readKeyword();
        case DOUBLE_QUOTE: readString();
        case SINGLE_QUOTE: readQuoted();
        case BACKTICK: readQuasiquote();
        case COMMA: readComma();
        case OCTOTHORPE: readReaderMacro();
        case num if (isNumericChar(num)): readNumber();
        case symb if (isLegalSymbolChar(symb)): readSymbol();
        default: Err({source:input, position:position, error:"read failed"});
        };
  }

  function readReaderMacro(): ReadResult {
    position++;  // consume OCTOTHORPE
    if ( !readerMacros.exists( current ) )
      return Err({source:input, position:position, error: "no reader macro found"});

    try {
      return switch ( readerMacros[ current] ) {
      case SingleFormMacro(macroFn): {
        position++; // consume macro character
        Ok(macroFn(rawRead()));
      }
      
      case StopCharacterMacro(stopChar, macroFn): {
        position++; // consume macro character
        var raw = rawRead(c -> c == stopChar, c -> c == BACKSLASH);
        position++; //consume the stop character
        Ok(macroFn(raw));
      }
      };
    } catch (e:Dynamic) {
      return Err({source:input, position:position, error: 'While processing a reader macro: $e'});
    }
  }

  function readKeyword(): ReadResult {
    position++; // consume the colon
    return readSymbol().map(symb -> Atom(Kwd(symb.symbolName())));
  }

  function readQuoted(): ReadResult {
    position++; // consume the quote
    return read().then(quoted -> Ok(Cons(Atom(Sym("QUOTE")), Cons(quoted, Atom(Nil)))));
  }

  function readQuasiquote(): ReadResult {
    position++;           // consume the quasiquote
    quasiquoteNesting++;  // increment quasiquote count
    return read()
      .onOk(ignore -> quasiquoteNesting--)
      .then(quoted -> Ok(Cons(Atom(Sym("#QUASIQUOTE")), Cons(quoted, Atom(Nil)))));
  }

  function readComma(): ReadResult {
    position++;
    if (quasiquoteNesting > 0) {
      quasiquoteNesting--;     // denest by one level for one expression
      var unquoteSymbol = Atom(Sym("#UNQUOTE"));

      if (current == AT_SIGN) {
        unquoteSymbol = Atom(Sym("#SPLICE"));
        position++;
      }

      return read()
        .onOk(ignore -> quasiquoteNesting++) // restore quasiquoteNesting
        .then(expr -> Ok(Cons(unquoteSymbol, Cons(expr, Atom(Nil)))));
    } else {
      return Err({source:input,
            position:position,
            error: "Comma not within a quasiquote"});
    }
  }

  function readCons():ReadResult {

    dropWhitespace();

    if (current == RIGHT_PAREN) {
      position++;
      return Ok(Atom(Nil));
    }

    if (current == PERIOD) {
      position++;
      return read()
        .then(form -> {
            dropWhitespace();
            if (current == RIGHT_PAREN) {
              position++;
              return Ok(form);
            }
            return Err({source:input, position:position, error:"only one term after the dot"});
          });
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

  // consumes input until stop charcter is encountered, then returns a string,
  // leaving the stop character on the input - or, if eof was encountered, then
  // input is eof.
  function rawRead(?stop:Int->Bool, ?escape:Int->Bool):UnicodeString {
    if (stop == null)
      stop = (c) -> isClosingBracket(c) || isWhitespace(c);

    var escapeOn = if (escape == null) false else escape(current);

    var p = position;
    while (( !stop(current) || escapeOn) && !eof) {
      escapeOn = if (escape == null) false else (!escapeOn && escape( current ));
      position++;
    }

    return input.substring(p,position);
  }

  public function new(source: UnicodeString) {
    input = source;
    position = 0;
    readerMacros = [ BACKSLASH =>  SingleFormMacro(interperetAsChar),
                     FORWARDSLASH => StopCharacterMacro( FORWARDSLASH, readRegularExpression)
                     ];
  }


}