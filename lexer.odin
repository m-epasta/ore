#+private
package ore

import "core:fmt"

TokenTyp :: enum {
	Wildcard, // .
	Lparen, // (
	Rparen, // )
	Lbracket, // [
	Rbracket, // ]
	Plus, // +
	Star, // *
	Question, // ?
	AnyDigit, // \d
	AnyWordChar, // \w
	AnyWhitespace, // \s
	Literal,
	End,
}

Token :: struct {
	typ:    TokenTyp,
	rune:   rune,
	offset: int,
}

// Returns the Parser since it is simply a tokens wrapper
tokenize :: proc(match: string) -> Parser {
	tokens := new([dynamic]Token)
	offset := 0

	for !is_at_end(tokens, offset) {
		c, ok := advance(tokens, &offset).?
		if !ok do break

		switch c {
		case '.':
			append(tokens, Token{typ = .Wildcard, rune = '.'})
		case '(':
			append(tokens, Token{typ = .Lparen, rune = '('})
		case ')':
			append(tokens, Token{typ = .Rparen, rune = ')'})
		case '[':
			append(tokens, Token{typ = .Lbracket, rune = '['})
		case ']':
			append(tokens, Token{typ = .Rbracket, rune = ']'})
		case '+':
			append(tokens, Token{typ = .Plus, rune = '+'})
		case '*':
			append(tokens, Token{typ = .Star, rune = '*'})
		case '?':
			append(tokens, Token{typ = .Question, rune = '?'})
		case '\\':
			if is_at_end(tokens, offset) {
				fmt.eprintf("Expected character after \\")
				break
			}

			escaped, ok := advance(tokens, &offset).?
			if !ok {
				fmt.eprintf("Expected character after \\")
				break
			}

			switch escaped {
			case 'd':
				append(tokens, Token{typ = .AnyDigit})
			case 's':
				append(tokens, Token{typ = .AnyWhitespace})
			case 'w':
				append(tokens, Token{typ = .AnyWordChar})
			case:
				append(tokens, Token{typ = .Literal, rune = escaped})
			}
		case:
			append(tokens, Token{typ = .Literal, rune = c})
		}
	}

	append(tokens, Token{typ = .End})

	return Parser{current = 0, tokens = tokens}
}
