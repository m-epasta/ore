package tests

import ".."
import "core:testing"

@(test)
literal :: proc(t: ^testing.T) {
	ok, err := ore.matches("God", "God")
	testing.expect(t, err == "", "Expected no error")
	testing.expect(t, ok, "Exact literal pattern should match.")
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
