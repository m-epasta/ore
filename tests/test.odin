package tests

import ".."
import "core:testing"

@(test)
literal :: proc(t: ^testing.T) {
	ok, err := ore.matches("God", "God")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "Exact literal pattern should match.")

	nok, nerr := ore.matches("God", "good")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !nok, "Different literal should not match.")


	sub, serr := ore.matches("abcde", "bcd")
	testing.expect(t, serr == "", "Expected no error")
	testing.expect(t, sub, "Literal should match at any position in input.")
}

@(test)
specialescapedchar :: proc(t: ^testing.T) {
	ok, err := ore.matches("\n", "\n")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "newline should be considered as a literal")

	ok2, err2 := ore.matches("\t", "\t")
	testing.expect(t, err2 == "", "Expected no error")
	testing.expect(t, ok2, "tab should be considered as a literal")

	ok3, err3 := ore.matches("\r", "\r")
	testing.expect(t, err3 == "", "Expected no error")
	testing.expect(t, ok3, "carriage return should be considered as a literal")

	ok4, err4 := ore.matches("\r\n", "\r\n")
	testing.expect(t, err4 == "", "Expected no error")
	testing.expect(t, ok4, "CRLF should be considered as a literal")
}

@(test)
wildcard :: proc(t: ^testing.T) {
	ok, err := ore.matches("ù", ".")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "Wildcard should match any character (representable by a rune)")

	multi, merr := ore.matches("ab", "..")
	testing.expect(t, merr == "", "Expected no error")
	testing.expect(t, multi, "Multiple wildcards should match multiple characters.")

	non, nerr := ore.matches("", ".")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !non, "Wildcard should not match empty input.")

	utf, uerr := ore.matches("日本語", "...")
	testing.expect(t, uerr == "", "Expected no error")
	testing.expect(t, utf, "Wildcard should match multi-byte UTF-8 characters.")
}

@(test)
anydigit :: proc(t: ^testing.T) {
	ok, err := ore.matches("1", "\\d")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "1 Should match any digit")

	d0, e0 := ore.matches("0", "\\d")
	testing.expect(t, e0 == "", "Expected no error")
	testing.expect(t, d0, "0 should match \\d")

	nond, ne := ore.matches("a", "\\d")
	testing.expect(t, ne == "", "Expected no error")
	testing.expect(t, !nond, "a should not match \\d")
}

@(test)
anyws :: proc(t: ^testing.T) {
	ok, err := ore.matches(" ", "\\s")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "whitespace should match any whitespace")

	tab, terr := ore.matches("\t", "\\s")
	testing.expect(t, terr == "", "Expected no error")
	testing.expect(t, tab, "tab should match \\s")

	non, nerr := ore.matches("x", "\\s")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !non, "x should not match \\s")
}

@(test)
anyword :: proc(t: ^testing.T) {
	ok, err := ore.matches("o", "\\w")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "o should match any word character")

	under, uerr := ore.matches("_", "\\w")
	testing.expect(t, uerr == "", "Expected no error")
	testing.expect(t, under, "_ should match \\w")

	non, nerr := ore.matches("@", "\\w")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !non, "@ should not match \\w")
}

@(test)
everythingbutdigit :: proc(t: ^testing.T) {
	ok, err := ore.matches("a", "\\D")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "a should match \\D")

	ok2, err2 := ore.matches("0", "\\D")
	testing.expect(t, err2 == "", "Expected no error")
	testing.expect(t, !ok2, "0 should not match \\D")
}

@(test)
everythingbutws :: proc(t: ^testing.T) {
	ok, err := ore.matches("a", "\\S")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "a should match \\S")

	ok2, err2 := ore.matches(" ", "\\S")
	testing.expect(t, err2 == "", "Expected no error")
	testing.expect(t, !ok2, "space should not match \\S")
}

@(test)
everythingbutword :: proc(t: ^testing.T) {
	ok, err := ore.matches("1", "\\W")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "1 should match \\W")

	ok2, err2 := ore.matches("a", "\\W")
	testing.expect(t, err2 == "", "Expected no error")
	testing.expect(t, !ok2, "a should not match \\S")
}

@(test)
characterclass :: proc(t: ^testing.T) {
	ok, err := ore.matches("cat", "[ct]")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "cat should match the group [ct]")

	c, cerr := ore.matches("c", "[abc]")
	testing.expect(t, cerr == "", "Expected no error")
	testing.expect(t, c, "c should match [abc]")

	non, nerr := ore.matches("x", "[abc]")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !non, "x should not match [abc]")
}

@(test)
negcharacterclass :: proc(t: ^testing.T) {
	ok, err := ore.matches("cat", "[^microslop]")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "cat should not match the group [microslop]")

	non, nerr := ore.matches("m", "[^abc]")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, non, "m should match negated class [^abc] since m is not in the set")
}

@(test)
quantplus :: proc(t: ^testing.T) {
	ok, err := ore.matches("aaa", "a+")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "aaa should match the OneOrMore repetition a+")

	ok2, err2 := ore.matches("aa", "a+")
	testing.expect(t, err2 == "", "Expected no error")
	testing.expect(t, ok2, "aa should match the OneOrMore repetition a+")

	single, serr := ore.matches("b", "b+")
	testing.expect(t, serr == "", "Expected no error")
	testing.expect(t, single, "Single character should match OneOrMore b+")

	non, nerr := ore.matches("c", "a+")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !non, "c should not match OneOrMore a+")

	non2, nerr2 := ore.matches("", "a+")
	testing.expect(t, nerr2 == "", "Expected no error")
	testing.expect(t, !non2, "Empty should not match OneOrMore a+")
}

@(test)
quantstar :: proc(t: ^testing.T) {
	ok, err := ore.matches("gb", "gb*")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "gb should match the ZeroOrMore repetition gb*")

	multiple, merr := ore.matches("gbbb", "gb*")
	testing.expect(t, merr == "", "Expected no error")
	testing.expect(t, multiple, "gbbb should match the ZeroOrMore repetition gb*")

	zero, zerr := ore.matches("a", "b*")
	testing.expect(t, zerr == "", "Expected no error")
	testing.expect(t, zero, "a should match the ZeroOrMore repetition b* (zero times)")


}

@(test)
quantexact :: proc(t: ^testing.T) {
	ok, err := ore.matches("suu", "u{2}")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "suu should match the Exact repetition u{2}")

	nok, nerr := ore.matches("su", "u{2}")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !nok, "su should not match the Exact repetition u{2}")

	exact3, e3err := ore.matches("abbbc", "b{3}")
	testing.expect(t, e3err == "", "Expected no error")
	testing.expect(t, exact3, "abbbc should match Exact repetition b{3}")

	toofew, tferr := ore.matches("abbc", "b{3}")
	testing.expect(t, tferr == "", "Expected no error")
	testing.expect(t, !toofew, "abbc should not match b{3}")

	group, gerr := ore.matches("susu", "(su){2}")
	testing.expect(t, gerr == "", "Expected no error")
	testing.expect(t, group, "susu should match group repetition (su){2}")
}


@(test)
quantexactormore :: proc(t: ^testing.T) {
	ok, err := ore.matches("suuu", "u{2,}")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "suuu should match the ExactOrMore repetition u{2,}")

	nok, nerr := ore.matches("su", "u{2,}")
	testing.expect(t, nerr == "", "Expected no error")
	testing.expect(t, !nok, "su should not match the ExactOrMore repetition u{2,}")

	many, merr := ore.matches("baaaaa", "a{3,}")
	testing.expect(t, merr == "", "Expected no error")
	testing.expect(t, many, "baaaaa should match ExactOrMore repetition a{3,}")

	group, gerr := ore.matches("sususu", "(su){2,}")
	testing.expect(t, gerr == "", "Expected no error")
	testing.expect(t, group, "sususu should match group repetition (su){2,}")

	group_non, gnerr := ore.matches("su", "(su){2,}")
	testing.expect(t, gnerr == "", "Expected no error")
	testing.expect(t, !group_non, "su should not match group repetition (su){2,}")
}

@(test)
alternation :: proc(t: ^testing.T) {
	ok, err := ore.matches("God", "(God|Devil)")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "God should match alternation (God|Devil)")

	ok2, err2 := ore.matches("God", "(God|Devil)")
	testing.expect(t, err2 == "", "Expected no error")
	testing.expect(t, ok2, "God should match alternation God|Devil")

	ok3, err3 := ore.matches("H", "(God|Devil)")
	testing.expect(t, err3 == "", "Expected no error")
	testing.expect(t, !ok3, "H should not match alternation (God|Devil)")

	ok4, err4 := ore.matches("4", "(God|Devil)")
	testing.expect(t, err4 == "", "Expected no error")
	testing.expect(t, !ok4, "4 should not match alternation God|Devil")
}

// Errors

@(test)
error_unclosed_bracket :: proc(t: ^testing.T) {
	_, err := ore.matches("a", "[")
	testing.expect(t, err != "", "Expected error for unclosed bracket")
}

@(test)
error_trailing_backslash :: proc(t: ^testing.T) {
	_, err := ore.matches("a", "a\\")
	testing.expect(t, err != "", "Expected error for trailing backslash")

	_, err2 := ore.matches("a", "\\")
	testing.expect(t, err2 != "", "Expected error for lone trailing backslash")
}

@(test)
error_unclosed_paren :: proc(t: ^testing.T) {
	_, err := ore.matches("a", "(a")
	testing.expect(t, err != "", "Expected error for unclosed paren")

	_, err2 := ore.matches("a", "(a(b")
	testing.expect(t, err2 != "", "Expected error for nested unclosed paren")
}

@(test)
error_unexpected_token :: proc(t: ^testing.T) {
	_, err := ore.matches("a", ")")
	testing.expect(t, err != "", "Expected error for unexpected token")

	_, err2 := ore.matches("a", "}")
	testing.expect(t, err2 != "", "Expected error for unexpected }")

	_, err3 := ore.matches("a", "{")
	testing.expect(t, err3 != "", "Expected error for unexpected { without preceding expression")
}
