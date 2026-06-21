#+private
package ore

Parser :: struct {
	current: uintptr,
	tokens:  ^[dynamic]Token,
}

parse :: proc(p: ^Parser) -> Maybe(Node) {
	node, concat_ok := parse_concat(p).?
	if !concat_ok do return nil

	if current(p).typ != TokenTyp.End do return nil

	return node
}

parse_concat :: proc(p: ^Parser) -> Maybe(Node) {
	node, factor_ok := parse_factor(p).?
	if !factor_ok do return nil

	for is_at_end(p) && current(p).typ != TokenTyp.Rparen && current(p).typ != TokenTyp.Rbracket {
		next_node, next_node_ok := parse_factor(p).?
		if !next_node_ok do return nil

		node := ConcatNode {
			left  = &node,
			right = &next_node,
		}
	}

	return node
}

parse_factor :: proc(p: ^Parser) -> Maybe(Node) {
	node, atom_ok := parse_atom(p).?
	if !atom_ok do return nil

	for !is_at_end(p) {
		#partial switch current(p).typ {
		case .Plus:
			if !consume(p, TokenTyp.Plus) do return nil
			node := PlusNode{&node}
		case .Star:
			if !consume(p, TokenTyp.Star) do return nil
			node := StarNode{&node}
		case .Question:
			if !consume(p, TokenTyp.Question) do return nil
			node := QuestionNode{&node}
		case:
			return node
		}
	}

	return nil
}

parse_atom :: proc(p: ^Parser) -> Maybe(Node) {
	token, not_end := advance(p).?
	if !not_end do return nil

	#partial switch token.typ {
	case .Wildcard:
		return Node{WildcardNode{}}
	case .AnyDigit:
		return Node{AnyDigitNode{}}
	case .AnyWordChar:
		return Node{AnyWordCharNode{}}
	case .AnyWhitespace:
		return Node{AnyWhitespaceNode{}}
	case .Literal:
		return Node{LiteralNode{char = token.rune}}
	case .Lparen:
		node, ok := parse_concat(p).?
		if !ok do return nil
		if !consume(p, TokenTyp.Rparen) do return nil

		return node
	case .Lbracket:
		node := CharacterClassNode{}
		for current(p).typ != TokenTyp.Rbracket {
			tok, ok := advance(p).?
			if !ok do return nil
			if tok.typ != TokenTyp.Literal do return nil
			append(&node.matches, tok.rune)
		}

		if !consume(p, TokenTyp.Rbracket) do return nil

		return Node{node}
	case:
		return nil
	}

	return nil
}
