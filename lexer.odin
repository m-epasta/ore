#+private
package ore

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
	tokens: [dynamic]Token
	i := 0

	for i < len(match) {
		r := rune(match[i])

		switch r {
		case '.':
			append(&tokens, Token{typ = .Wildcard, rune = '.'})
		case '(':
			append(&tokens, Token{typ = .Lparen, rune = '('})
		case ')':
			append(&tokens, Token{typ = .Rparen, rune = ')'})
		case '[':
			append(&tokens, Token{typ = .Lbracket, rune = '['})
		case ']':
			append(&tokens, Token{typ = .Rbracket, rune = ']'})
		case '+':
			append(&tokens, Token{typ = .Plus, rune = '+'})
		case '*':
			append(&tokens, Token{typ = .Star, rune = '*'})
		case '?':
			append(&tokens, Token{typ = .Question, rune = '?'})
		case '\\':
			i += 1
			if i >= len(match) {
				append(&tokens, Token{typ = .End})
				return Parser{err = "expected character after '\\'", tokens = tokens}
			}

			escaped := rune(match[i])
			switch escaped {
			case 'd':
				append(&tokens, Token{typ = .AnyDigit})
			case 's':
				append(&tokens, Token{typ = .AnyWhitespace})
			case 'w':
				append(&tokens, Token{typ = .AnyWordChar})
			case:
				append(&tokens, Token{typ = .Literal, rune = escaped})
			}
		case:
			append(&tokens, Token{typ = .Literal, rune = r})
		}

		i += 1
	}

	append(&tokens, Token{typ = .End})

	return Parser{current = 0, tokens = tokens}
}
