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

free_node :: proc(node: ^Node) {
	if node == nil do return

	#partial switch n in node.typ {
	case PlusNode:
		free_node(n.child)
	case StarNode:
		free_node(n.child)
	case QuestionNode:
		free_node(n.child)
	case ConcatNode:
		free_node(n.left)
		free_node(n.right)
	case CharacterClassNode:
		delete(n.matches)
	}

	free(node)
}
