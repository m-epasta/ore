package tests

import ".."
import "core:testing"

@(test)
literal :: proc(t: ^testing.T) {
	ok, err := ore.matches("God", "God")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "Exact literal pattern should match.")
}

@(test)
wildcard :: proc(t: ^testing.T) {
	ok, err := ore.matches("ù", ".")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "Wildcard should match any character (representable by a rune)")
}

@(test)
anydigit :: proc(t: ^testing.T) {
	ok, err := ore.matches("1", "\\d")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "1 Should match any digit")
}

@(test)
anyws :: proc(t: ^testing.T) {
	ok, err := ore.matches(" ", "\\s")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "whitespace should match any whitespace")
}

@(test)
anyword :: proc(t: ^testing.T) {
	ok, err := ore.matches("o", "\\w")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "o should match any word character")
}

@(test)
characterclass :: proc(t: ^testing.T) {
	ok, err := ore.matches("cat", "[ct]")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "cat should match the group [ct]")
}

@(test)
negcharacterclass :: proc(t: ^testing.T) {
	ok, err := ore.matches("cat", "[^microslop]")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "cat should not match the group [microslop]")
}

@(test)
quantplus :: proc(t: ^testing.T) {
	ok, err := ore.matches("aaa", "a+")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "aaa should match the OneOrMore repetition a+")

	ok2, err2 := ore.matches("aa", "a+")
	testing.expect(t, err2 == "", "Expected no error")
	testing.expect(t, ok2, "aaa should match the OneOrMore repetition a+")
}

@(test)
quantstar :: proc(t: ^testing.T) {
	ok, err := ore.matches("gb", "gb*")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "gb should match the ZeroOrMore repetition gb*")
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
}

@(test)
error_unclosed_paren :: proc(t: ^testing.T) {
	_, err := ore.matches("a", "(a")
	testing.expect(t, err != "", "Expected error for unclosed paren")
}

@(test)
error_unexpected_token :: proc(t: ^testing.T) {
	_, err := ore.matches("a", ")")
	testing.expect(t, err != "", "Expected error for unexpected token")
}
