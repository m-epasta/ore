#+private
package ore

// TODO: merge node_types with node

Node :: struct {
	typ: TypeNode,
}

TypeNode :: union {
	WildcardNode,
	LiteralNode,
	AnyDigitNode,
	AnyWhitespaceNode,
	AnyWordCharNode,
	CharacterClassNode,
	EveythingButDigitNode,
	EverythingButWhitespaceNode,
	EverythingButWordCharNode,
	PlusNode,
	StarNode,
	QuestionNode,
	ConcatNode,
}

WildcardNode :: struct {}
LiteralNode :: struct {
	char: rune,
}
AnyDigitNode :: struct {}
AnyWhitespaceNode :: struct {}
AnyWordCharNode :: struct {}
EveythingButDigitNode :: struct {}
EverythingButWhitespaceNode :: struct {}
EverythingButWordCharNode :: struct {}
CharacterClassNode :: struct {
	matches: [dynamic]rune,
	neg:     bool,
}
PlusNode :: struct {
	using child: ^Node,
}
StarNode :: struct {
	using child: ^Node,
}
QuestionNode :: struct {
	using child: ^Node,
}
ConcatNode :: struct {
	using left:  ^Node,
	using right: ^Node,
}
