package ore

Matcher :: struct {
	pos:   uintptr,
	input: string,
}

match :: proc(ast: ^Node, input: string) -> bool {
	matcher := new(Matcher)
	defer free(matcher)

	matcher.input = input
	matcher.pos = 0

	// TODO: Match on ast.typ to execute match_specific

	return false
}

match_specific :: proc {
	matchWildcardNode,
	matchLiteralNode,
	matchAnyDigitNode,
	matchAnyWhitespaceNode,
	matchAnyWordCharNode,
	matchCharacterClassNode,
	matchPlusNode,
	matchStarNode,
	matchQuestionNode,
	matchConcatNode,
}

matchWildcardNode :: proc(matcher: ^Matcher, node: ^WildcardNode) {

}
matchLiteralNode :: proc(matcher: ^Matcher, node: ^LiteralNode) {}
matchAnyDigitNode :: proc(matcher: ^Matcher, node: ^AnyDigitNode) {}
matchAnyWhitespaceNode :: proc(matcher: ^Matcher, node: ^AnyWhitespaceNode) {}
matchAnyWordCharNode :: proc(matcher: ^Matcher, node: ^AnyWordCharNode) {}
matchCharacterClassNode :: proc(matcher: ^Matcher, node: ^CharacterClassNode) {}
matchPlusNode :: proc(matcher: ^Matcher, node: ^PlusNode) {}
matchStarNode :: proc(matcher: ^Matcher, node: ^StarNode) {}
matchQuestionNode :: proc(matcher: ^Matcher, node: ^QuestionNode) {}
matchConcatNode :: proc(matcher: ^Matcher, node: ^ConcatNode) {}
