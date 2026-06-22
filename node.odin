#+private
package ore

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
	RangeRepNode,
	CaptureNode,
	BackrefNode,
	ConcatNode,
	AlternationNode,
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
RangeRepNode :: struct {
	from:        int,
	to:          int,
	using child: ^Node,
}
CaptureNode :: struct {
	id:        int,
	using child: ^Node,
}

BackrefNode :: struct {
	id: int,
}

ConcatNode :: struct {
	using left:  ^Node,
	using right: ^Node,
}
AlternationNode :: struct {
	exprs: [dynamic]^Node,
}

