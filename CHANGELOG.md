# v1.0.1

* Pijamas now supports DLang frontend 2.086

# v1.0.0

* Moved unit-tests to an separate foolder to avoid pollute other projects with
    Pijamas unit-testing dependencies.
* Launch tests using silly, unit-threaded, trial and dunit.
* Assertions now throws AssertException that it's an alias to AssertError or to
    unit-threaded UnitTestException;
* Added expect and .to()
* Now Assertion is a struct

# v0.3.5

* Switching to GitHub CI
* Update tests to use Silly 1.1
* Tweaks on tests dependencies (optional: true)

# v0.3.4

* Update to DLang frontend 2.91
* Using std.math.isClose instead of .approxEquals
* Added .close as alias of .approxEquals

# v0.3.3

* .throw must be @trusted, to allow to catch Errors
* Added .biggerOrEqualThan and .smallerOrEqualThan

# v0.3.2

* .equals and others, must be @trusted to allow to call @system opEquals
* .approxEquals to do approximated equality of float types

# v0.3.1

* Make Pijamas @safe

# v0.3.0

* Rename module to pijamas.
* .empty for arrays, associative arrays and strings.

# v0.2.2

Versions v0.2.x must keep being source compatible with Pyjamas.

* Ignores failing Appveyor with LDC on 32 bit Windows. Looks that its a problem
    of 32bit DUB+LDC 1.21.0 on Windows.

# v0.2.2-beta

Versions v0.2.x must keep being source compatible with Pyjamas.

* Update to DLang frontend 2.090
* Autogeneration of GH Pages with documentation
* Rewrite tests to use Silly
* Fixed false positives with should.exists . The old approach to see if is convertible to null, wasn't working.
* Fixed .match(ctRegex) . Now mimics how std.regex : match handles it
* Improved the test battery to detect false positives.
* Documenting the source code, so ddoc can generate the documentation.


