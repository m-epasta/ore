#+private
package ore

advance :: proc {
	tok_advance,
	node_advance,
	matcher_advance,
}

consume :: proc {
	node_consume,
}

current :: proc {
	node_current,
	matcher_current,
}

is_at_end :: proc {
	tok_is_at_end,
	node_is_at_end,
	matcher_is_at_end,
}

tok_advance :: proc(tokens: ^[dynamic]Token, offset: ^int) -> Maybe(rune) {
	if is_at_end(tokens, offset^) do return nil
	offset^ += 1
	return tokens[offset^].rune
}

tok_is_at_end :: proc(tokens: ^[dynamic]Token, offset: int) -> bool {
	return offset >= len(tokens)
}

node_advance :: proc(p: ^Parser) -> Maybe(Token) {
	if is_at_end(p) do return nil

	token := p.tokens[p.current]
	p.current += 1
	return token
}

// False means failure
node_consume :: proc(p: ^Parser, typ: TokenTyp) -> bool {
	if current(p).typ != typ do return false
	advance(p)
	return true
}

node_current :: proc(p: ^Parser) -> Token {
	return p.tokens[p.current]
}

node_is_at_end :: proc(p: ^Parser) -> bool {
	return p.tokens[p.current].typ == TokenTyp.End
}

matcher_advance :: proc(matcher: ^Matcher) {
	matcher.pos += 1
}

matcher_current :: proc(matcher: ^Matcher) -> rune {
	return cast(rune)matcher.input[matcher.pos]
}

matcher_is_at_end :: proc(matcher: ^Matcher) -> bool {
	return cast(int)matcher.pos >= len(matcher.input)
}
