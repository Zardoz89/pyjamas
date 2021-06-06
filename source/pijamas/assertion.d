/**
 * Pijamas, a BDD assertion library for D.
 *
 * License: Licensed under the MIT license. See LICENSE for more information.
 */
module pijamas.assertion;

import std.algorithm : canFind, isSorted;
import std.conv : to;
import std.range : isInputRange, isForwardRange, hasLength, ElementEncodingType, empty;
import std.regex : Regex, StaticRegex;
import std.traits : hasMember, isSomeString, isCallable, isAssociativeArray,
  isImplicitlyConvertible, Unqual;

import pijamas.exception;

/**
 * The function **should** it's an helper or syntax sugar to create the assertation.
 * Because of D’s lookup shortcut syntax, one is able to use both `should(obj)` and `obj.should` to
 * get an object wrapped around an Assertion instance
 */
public Assertion!T should(T)(auto ref T context)
{
  return Assertion!T(context);
}

/**
 * The function **expect** it's an helper or syntax sugar to create the assertation.
 * Because of D’s lookup shortcut syntax, one is able to use both `expect(obj)` and `obj.expect` to
 * get an object wrapped around an Assertion instance
 */
public alias expect = should;

/// Class returned by should, that it's used to generate the fluent API
struct Assertion(T)
{
  private static bool callable = isCallable!T;
  private bool negated = false;
  private string operator = "be";
  private T context;

  /// Creates a instance of Assertion, wrapping a value or object
  this(T _context) @safe pure nothrow
  {
    context = _context;
  }
  ///ditto
  this(ref T _context) @safe pure nothrow
  {
    context = _context;
  }

  /// Identity function. Simply does nothing beyond making assertation more human friendly
  alias be = id;
  ///ditto
  alias to = id;
  ///ditto
  alias as = id;
  ///ditto
  alias of = id;
  ///ditto
  alias a = id;
  ///ditto
  alias and = id;
  ///ditto
  alias have = id;
  ///ditto
  alias which = id;
  ///ditto
  Assertion id() @nogc @safe pure nothrow
  {
    return this;
  }

  /**
   * This function negates the wrapper assertion. With it, one can express fluent assertions without much effort.
   *
   * Examples:
   * ```
   * 10.should.not.equal(2); // OK
   * 10.should.not.equal(10); // Throws an Exception "expected 10 not to be 10"
   * ```
   */
  Assertion not() @nogc @safe pure nothrow
  {
    negated = !negated;
    return this;
  }

  // Helper that evaluates the asserted expression
  private U ok(U, V)(lazy U expr, V value, string file = __FILE__, size_t line = __LINE__) @safe
  {
    if (negated ? !expr : expr) {
      return expr;
    }
    throw new AssertException(this.message(value), file, line);
  }

  // Helper that evaluates the asserted expression
  private U ok(U)(lazy U expr, string file = __FILE__, size_t line = __LINE__) @safe
  {
    if (negated ? !expr : expr) {
      return expr;
    }
    throw new AssertException(this.message(), file, line);
  }

  // Generates string message when an assertation fails
  private string message(U)(U other) @trusted
  {
    import std.string : format;
    return format("expected %s to %s%s%s", context.to!string, (negated ?
        "not " : ""), operator, (" " ~ other.to!string));
  }

  // Generates string message when an assertation fails
  private string message() @trusted
  {
    import std.string : format;
    return format("expected %s to %s%s", context.to!string, (negated ? "not " : ""), operator);
  }

  /**
   * Asserts for equality between two objects. Returns the value wrapped around the assertion.
   *
   * Examples:
   * ```
   * [1, 2, 3, 4].should.equal([1, 2, 3, 4]);
   * 255.should.equal(10); // Throws an Exception "expected 255 to equal 10"
   * ```
   */
  T equal(U)(U other, string file = __FILE__, size_t line = __LINE__) @trusted
  {
    this.ok(context == other, other, file, line);
    return context;
  }

  // Ripped from std.math
  private template CommonDefaultFor(T,U)
  {
    import std.traits : CommonType;
    import std.algorithm.comparison : min;

    alias baseT = FloatingPointBaseType!T;
    alias baseU = FloatingPointBaseType!U;

    enum CommonType!(baseT, baseU) CommonDefaultFor = 10.0L ^^ -((min(baseT.dig, baseU.dig) + 1) / 2 + 1);
  }

  // Ripped from std.math
  private template FloatingPointBaseType(T)
  {
    import std.traits : isFloatingPoint;
    import std.range.primitives : ElementType;
    static if (isFloatingPoint!T)
    {
      alias FloatingPointBaseType = Unqual!T;
    }
    else static if (isFloatingPoint!(ElementType!(Unqual!T)))
    {
      alias FloatingPointBaseType = Unqual!(ElementType!(Unqual!T));
    }
    else
    {
      alias FloatingPointBaseType = real;
    }
  }

  /**
   * Asserts that a float type is aproximated equal. Returns the valued wrapped around the assertion
   *
   * Params:
   *   other = Value to compare to compare.
   *   maxRelDiff = Maximum allowable relative difference.
   *   Setting to 0.0 disables this check. Default depends on the type of
   *   `other` and the original valie: It is approximately half the number of decimal digits of
   *   precision of the smaller type.
   *   maxAbsDiff = Maximum absolute difference. This is mainly usefull
   *   for comparing values to zero. Setting to 0.0 disables this check.
   *   Defaults to `0.0`.
   *   file = filename
   *   line = line number inside of file
   *
   * Examples:
   * ```
   * double d = 0.1;
   * double d2 = d + 1e-10;
   * d.should.not.be.equal(d2);
   * d.should.be.approxEqual(d2);
   * ```
   */
  T approxEqual(U = double)(U other, U maxRelDiff = CommonDefaultFor!(T,U), U maxAbsDiff = 0.0,
      string file = __FILE__, size_t line = __LINE__) @trusted
      if (is(T : real) && __traits(isFloating, T) && is(U : real) && __traits(isFloating, U))
  {
    operator = "be approximated equal than";
    static if (__traits(compiles, { import std.math : isClose; })) {
      import std.math : isClose;
      this.ok(isClose(context, other, maxRelDiff, maxAbsDiff), other, file, line);
    } else {
      import std.math : approxEqual;
      this.ok(approxEqual(context, other, maxRelDiff, maxAbsDiff), other, file, line);
    }
    return context;
  }

  /**
   * Alias to approxEqual
   *
   * Examples:
   * ```
   * double d = 0.1;
   * double d2 = d + 1e-10;
   * d.should.not.be.close(d2);
   * d.should.be.close(d2);
   * ```
   */
  alias close = approxEqual;

  /**
   * Asserts whether a value exists - currently simply compares it with null, if it is a pointer, a class or a string.
   * Returns the value wrapped around the assertion.
   *
   * Examples:
   * ```
   * auto exists = "I exist!";
   * should(exists).exist;
   * string doesntexist;
   * doesntexist.should.exist; // Throws an Exception "expected null to exist"
   * Object aObject;
   * aClass.should.not.exists;
   * ```
   */
  T exist(string file = __FILE__, size_t line = __LINE__) @safe
  {
    import std.traits : isPointer, isSomeString;

    static if (isPointer!T || isSomeString!T || __traits(compiles, () {
        T t;
        assert(t is null);
      }))
    {
      if (context is null) {
        this.ok(false, file, line);
      }
    }
    return context;
  }

  /**
   * Asserts if a value is bigger than another value. Returns the result.
   *
   * Examples:
   * ```
   * "z".should.be.biggerThan("a");
   * 10.should.be.biggerThan(1);
   * ```
   */
  bool biggerThan(U)(U other, string file = __FILE__, size_t line = __LINE__) @trusted
  {
    operator = "be bigger than";
    return this.ok(context > other, other, file, line);
  }

  /**
   * Asserts if a value is bigger or equal than another value. Returns the result.
   *
   * Examples:
   * ```
   * "z".should.be.biggerOrEqualThan("a");
   * 10.should.be.biggerOrEqualThan(10);
   * 20.should.be.biggerOrEqualThan(10);
   * ```
   */
  bool biggerOrEqualThan(U)(U other, string file = __FILE__, size_t line = __LINE__) @trusted
  {
    operator = "be bigger or equal than";
    return this.ok(context >= other, other, file, line);
  }

  /**
   * Asserts if a value is smaller than another value. Returns the result.
   *
   * Examples:
   * ```
   * 10.should.be.smallerThan(100);
   * false.should.be.smallerThan(true);
   * ```
   */
  bool smallerThan(U)(U other, string file = __FILE__, size_t line = __LINE__) @trusted
  {
    operator = "be smaller than";
    return this.ok(context < other, other, file, line);
  }

  /**
   * Asserts if a value is smaller or euqal than another value. Returns the result.
   *
   * Examples:
   * ```
   * 10.should.be.smallerOrEqualThan(100);
   * 10.should.be.smallerOrEqualThan(10);
   * false.should.be.smallerOrEqualThan(true);
   * ```
   */
  bool smallerOrEqualThan(U)(U other, string file = __FILE__, size_t line = __LINE__) @trusted
  {
    operator = "be smaller or equal than";
    return this.ok(context <= other, other, file, line);
  }

  static if (isForwardRange!T && __traits(compiles, context.isSorted))
  {
    /**
     * Asserts whether a forward range is sorted.
     *
     * Examples:
     * ```
     * [1, 2, 3, 4].should.be.sorted;
     * [1, 2, 0, 4].should.not.be.sorted;
     * ```
     */
    bool sorted(string file = __FILE__, size_t line = __LINE__) @trusted
    {
      operator = "be sorted";
      return this.ok(context.isSorted, file, line);
    }
  }

  static if (isAssociativeArray!T)
  {
    /**
     * Asserts for an associative array to have a key equal to other.
     *
     * Examples:
     * ```
     * ["something": 10].should.have.key("something");
     * ```
     */
    void key(U)(U other, string file = __FILE__, size_t line = __LINE__) @trusted
    {
      operator = "have key";
      this.ok(!(other !in context), other, file, line);
    }
  }

  static if (isInputRange!T || isAssociativeArray!T)
  {
    /**
     * Asserts for an input range wrapped around an Assertion to contain/include a value.
     *
     * Examples:
     * ```
     * [1, 2, 3, 4].should.include(3);
     * "something".should.not.include('o');
     * "something".should.include("th");
     * ```
     */
    U include(U)(U other, string file = __FILE__, size_t line = __LINE__) @trusted
    {
      static if (isAssociativeArray!T) {
        auto pool = context.values;
      } else {
        auto pool = context;
      }

      operator = "contain value";
      this.ok(canFind(pool, other), other, file, line);
      return other;
    }

    ///ditto
    alias value = include;
    ///ditto
    alias contain = include;
  }

  static if (hasLength!T || hasMember!(T, "string") || isSomeString!T)
  {
    /**
     * Asserts for the .length property or function value to equal some value.
     *
     * Examples:
     * ```
     * [1, 2, 3, 4].should.have.length(4);
     * "abcdefg".should.have.length(0);
     * // ^^ - Throws an Exception "expected 'abcdefg' to have length of 0"
     * ```
     */
    U length(U)(U len, string file = __FILE__, size_t line = __LINE__) @trusted
    {
      operator = "have length of";
      this.ok(context.length == len, len, file, line);
      return len;
    }

    /**
     * Asserts for the .length property or function value to be equal to 0.
     *
     * Examples:
     * ```
     * [].should.be.empty;
     * "".should.be.empty;
     * ```
     */
    bool empty(string file = __FILE__, size_t line = __LINE__) @trusted
    {
      operator = "is empty";
      return this.ok(context.length == 0, file, line);
    }
  }

  import std.regex : Regex, isRegexFor;
  import std.traits : isSomeString;

  static if (isSomeString!T)
  {

    /**
     * Asserts for a string wrapped around the Assertion to match a regular expression.
     *
     * Examples:
     * ```
     * "something weird".should.match(`[a-z]+`);
     * "something weird".should.match(regex(`[a-z]+`));
     * "something 2 weird".should.not.match(ctRegex!(`^[a-z]+$`));
     * "1234numbers".should.match(`[0-9]+[a-z]+`);
     * "1234numbers".should.not.match(`^[a-z]+`);
     * ```
     */
    auto match(RegEx)(RegEx re, string file = __FILE__, size_t line = __LINE__) @safe
        if (isSomeString!T && isRegexFor!(RegEx, T))
    {
      import std.regex : match;

      auto m = match(context, re);
      operator = "match";
      this.ok(!m.empty, re, file, line);
      return m;
    }

    ///ditto
    auto match(U)(U re, string file = __FILE__, size_t line = __LINE__) @safe
        if (isSomeString!T && isSomeString!U)
    {
      import std.regex : regex, match;

      auto m = match(context, regex(re));
      operator = "match";
      this.ok(!m.empty, re, file, line);
      return m;
    }
  }

  static if (is(T == bool))
  {
    /**
     * Asserts for a boolean value to be equal to true.
     *
     * Examples:
     * ```
     * true.should.be.True;
     * (1 == 1).should.be.True;
     * ```
     */
    bool True(string file = __FILE__, size_t line = __LINE__) @safe
    {
      return this.ok(context == true, true, file, line);
    }

    /**
     * Asserts for a boolean value to be equal to true.
     *
     * Examples:
     * ```
     * false.should.be.False;
     * (1 != 1).should.be.False;
     * ```
     */
    bool False(string file = __FILE__, size_t line = __LINE__) @safe
    {
      return !this.ok(context == false, false, file, line);
    }
  }

  static if (isCallable!T)
  {
    /**
     * Asserts whether a callable object wrapped around the assertion throws an exception of type T.
     *
     * Examples:
     * ```
     * void throwing()
     * {
     *   throw new Exception("I throw with 0!");
     * }

     * should(&throwing).Throw!Exception;

     * void notThrowing()
     * {
     *   return;
     * }
     *
     * should(&notThrowing).not.Throw;
     * ```
     */
    void Throw(T : Throwable = Exception)(string file = __FILE__, size_t line = __LINE__) @trusted
    {
      operator = "throw";
      bool thrown = false;
      try {
        this.context();
      } catch (T) {
        thrown = true;
      }
      this.ok(thrown, file, line);
    }
  }

}

@("Should(v)")
@safe unittest
{
  //  it("returns an Assertion", {
  assert(is(typeof(10.should) == Assertion!int));
  assert(is(typeof(10f.expect) == Assertion!float));
}

@("Should Assertion")
@safe unittest
{
  //  it("can be instantiated for ranges of structs without `opCmp`", {
  struct Test
  {
    int a;
    int b;
  }

  cast(void)[Test(2, 3)].should;
}

@("Should Assertion.message")
@safe unittest
{
  //  it("returns the correct message for binary operators",
  {
    auto a = Assertion!int(10);
    a.operator = "equal";
    assert(a.message(20) == "expected 10 to equal 20");
  }

  //  it("returns the correct message for unary operators",
  {
    auto a = Assertion!string("function");
    a.operator = "throw";
    assert(a.message == "expected function to throw");
  }

  //  it("returns the correct message for negated operators",
  {
    auto a = Assertion!int(10);
    a.operator = "be";
    assert(a.not.message(false) == "expected 10 to not be false");
  }
}
