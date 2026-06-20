package ore

TypeNode :: union {
	WildcardNode,
	LiteralNode,
	AnyDigitNode,
	AnyWhitespaceNode,
	AnyWordCharNode,
	CharacterClassNode,
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
CharacterClassNode :: struct {
	matches: [dynamic]rune,
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
