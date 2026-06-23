#+private
package ore

import "core:c/libc"
import "core:unicode/utf8"

isdigit :: proc(c: rune) -> bool {
	return libc.isdigit(i32(c)) != 0
}

// Include '_'
isalpha :: proc(c: rune) -> bool {
	return libc.isalpha(i32(c)) != 0 || c == '_'
}

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
	_, w := utf8.decode_rune(matcher.input[matcher.pos:])
	matcher.pos += uintptr(w)
	for id in matcher.open_groups {
		matcher.groups[id].end = matcher.pos
	}
}

matcher_current :: proc(matcher: ^Matcher) -> rune {
	r, _ := utf8.decode_rune(matcher.input[matcher.pos:])
	return r
}

matcher_is_at_end :: proc(matcher: ^Matcher) -> bool {
	return cast(int)matcher.pos >= len(matcher.input)
}

// NOTE: This may be changed, it is used as a bound to not have too large memory footprint
MAX_CAPTURE_GROUPS :: 32

GroupRange :: struct {
	start: uintptr,
	end:   uintptr,
}

UNSET_GROUP :: max(uintptr)

MatcherSnapshot :: struct {
	pos:    uintptr,
	groups: [MAX_CAPTURE_GROUPS]GroupRange,
}

snapshot_matcher :: proc(m: ^Matcher) -> MatcherSnapshot {
	return {pos = m.pos, groups = m.groups}
}

restore_matcher :: proc(m: ^Matcher, snap: MatcherSnapshot) {
	m.pos = snap.pos
	m.groups = snap.groups
}
