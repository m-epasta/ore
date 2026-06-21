#+private
package ore

import "core:c/libc"
import "core:slice"

Matcher :: struct {
	pos:   uintptr,
	input: string,
}

match :: proc(ast: ^Node, input: string) -> bool {
	matcher := new(Matcher)
	defer free(matcher)

	matcher.input = input
	matcher.pos = 0

	if !match_node(matcher, ast) do return false

	return is_at_end(matcher)
}

match_node :: proc(matcher: ^Matcher, node: ^Node) -> bool {
	switch &typ in node.typ {
	case WildcardNode:
		return matchWildcardNode(matcher, &typ)
	case LiteralNode:
		return matchLiteralNode(matcher, &typ)
	case AnyDigitNode:
		return matchAnyDigitNode(matcher, &typ)
	case AnyWordCharNode:
		return matchAnyWordCharNode(matcher, &typ)
	case AnyWhitespaceNode:
		return matchAnyWhitespaceNode(matcher, &typ)
	case CharacterClassNode:
		return matchCharacterClassNode(matcher, &typ)
	case PlusNode:
		return matchPlusNode(matcher, &typ)
	case StarNode:
		return matchStarNode(matcher, &typ)
	case QuestionNode:
		return matchQuestionNode(matcher, &typ)
	case ConcatNode:
		return matchConcatNode(matcher, &typ)
	}

	return false
}

matchWildcardNode :: proc(matcher: ^Matcher, node: ^WildcardNode) -> bool {
	if is_at_end(matcher) do return false
	advance(matcher)
	return true
}

matchLiteralNode :: proc(matcher: ^Matcher, node: ^LiteralNode) -> bool {
	if is_at_end(matcher) do return false
	out := current(matcher) == node.char
	if out do advance(matcher)

	return out
}

matchAnyDigitNode :: proc(matcher: ^Matcher, node: ^AnyDigitNode) -> bool {
	if is_at_end(matcher) || libc.isdigit(cast(i32)current(matcher)) != 0 do return false

	advance(matcher)
	return true
}

matchAnyWhitespaceNode :: proc(matcher: ^Matcher, node: ^AnyWhitespaceNode) -> bool {
	if is_at_end(matcher) || libc.isspace(cast(i32)current(matcher)) != 0 do return false

	advance(matcher)
	return true
}

matchAnyWordCharNode :: proc(matcher: ^Matcher, node: ^AnyWordCharNode) -> bool {
	if is_at_end(matcher) || libc.isalpha(cast(i32)current(matcher)) != 0 || current(matcher) != '_' do return false

	advance(matcher)
	return true
}

matchCharacterClassNode :: proc(matcher: ^Matcher, node: ^CharacterClassNode) -> bool {
	if is_at_end(matcher) || !slice.contains(node.matches[:], current(matcher)) do return false

	advance(matcher)
	return true
}

matchPlusNode :: proc(matcher: ^Matcher, node: ^PlusNode) -> bool {
	if is_at_end(matcher) || !try_match_rep(matcher, node.child) do return false

	for try_match_rep(matcher, node.child) {}
	return true
}

matchStarNode :: proc(matcher: ^Matcher, node: ^StarNode) -> bool {
	for try_match_rep(matcher, node.child) {}
	return true
}

matchQuestionNode :: proc(matcher: ^Matcher, node: ^QuestionNode) -> bool {
	try_match_rep(matcher, node.child)

	return true
}

matchConcatNode :: proc(matcher: ^Matcher, node: ^ConcatNode) -> bool {
	start := matcher.pos
	if !match_node(matcher, node.left) {
		matcher.pos = start
		return false
	}

	if !match_node(matcher, node.right) {
		matcher.pos = start
		return false
	}

	return true
}

try_match_rep :: proc(matcher: ^Matcher, child: ^Node) -> bool {
	start := matcher.pos

	if !match_node(matcher, child) {
		matcher.pos = start
		return false
	}

	if matcher.pos == start do return false

	return true
}
