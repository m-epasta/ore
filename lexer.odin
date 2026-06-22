#+private
package ore

TokenTyp :: enum {
	Wildcard, // .
	Caret, // ^
	Lparen, // (
	Rparen, // )
	Pipe, // |
	Lbracket, // [
	Rbracket, // ]
	Lbrace, // {
	Rbrace, // }
	Comma, // ,
	Plus, // +
	Star, // *
	Question, // ?
	AnyDigit, // \d
	AnyWhitespace, // \s
	AnyWordChar, // \w
	EverythingButDigit, // \D
	EverythingButWhitespace, // \S
	EverythingButWordChar, // \W
	Literal,
	End, // Special token used by the lexer, does not represent any pattern
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
		case '^':
			append(&tokens, Token{typ = .Caret, rune = '^'})
		case '(':
			append(&tokens, Token{typ = .Lparen, rune = '('})
		case ')':
			append(&tokens, Token{typ = .Rparen, rune = ')'})
		case '|':
			append(&tokens, Token{typ = .Pipe, rune = '|'})
		case '[':
			append(&tokens, Token{typ = .Lbracket, rune = '['})
		case ']':
			append(&tokens, Token{typ = .Rbracket, rune = ']'})
		case '{':
			append(&tokens, Token{typ = .Lbrace, rune = '{'})
		case '}':
			append(&tokens, Token{typ = .Rbrace, rune = '}'})
		case '+':
			append(&tokens, Token{typ = .Plus, rune = '+'})
		case '*':
			append(&tokens, Token{typ = .Star, rune = '*'})
		case '?':
			append(&tokens, Token{typ = .Question, rune = '?'})
		case ',':
			append(&tokens, Token{typ = .Comma, rune = ','})
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
			case 'D':
				append(&tokens, Token{typ = .EverythingButDigit})
			case 'S':
				append(&tokens, Token{typ = .EverythingButWhitespace})
			case 'W':
				append(&tokens, Token{typ = .EverythingButWordChar})
			case 't':
				append(&tokens, Token{typ = .Literal, rune = '\t'})
			case 'n':
				append(&tokens, Token{typ = .Literal, rune = '\n'})
			case 'r':
				append(&tokens, Token{typ = .Literal, rune = '\r'})
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
