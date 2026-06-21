#+private
package ore

Parser :: struct {
	current: uintptr,
	tokens:  [dynamic]Token,
	err:     Error,
}

parse :: proc(p: ^Parser) -> Maybe(^Node) {
	node, concat_ok := parse_concat(p).?
	if !concat_ok do return nil

	if current(p).typ != TokenTyp.End {
		p.err = "unexpected token after expression"
		return nil
	}

	return node
}

parse_concat :: proc(p: ^Parser) -> Maybe(^Node) {
	left, ok := parse_factor(p).?
	if !ok do return nil

	for !is_at_end(p) && current(p).typ != TokenTyp.Rparen && current(p).typ != TokenTyp.Rbracket {
		right, right_ok := parse_factor(p).?
		if !right_ok {
			free_node(left)
			return nil
		}

		node := new(Node)
		node.typ = ConcatNode{left = left, right = right}
		left = node
	}

	return left
}

parse_factor :: proc(p: ^Parser) -> Maybe(^Node) {
	child, atom_ok := parse_atom(p).?
	if !atom_ok {
		if p.err == "" {
			p.err = "expected expression"
		}
		return nil
	}

	for !is_at_end(p) {
		#partial switch current(p).typ {
		case .Plus:
			if !consume(p, TokenTyp.Plus) do return nil
			node := new(Node)
			node.typ = PlusNode{child = child}
			child = node
		case .Star:
			if !consume(p, TokenTyp.Star) do return nil
			node := new(Node)
			node.typ = StarNode{child = child}
			child = node
		case .Question:
			if !consume(p, TokenTyp.Question) do return nil
			node := new(Node)
			node.typ = QuestionNode{child = child}
			child = node
		case:
			return child
		}
	}

	return child
}

parse_atom :: proc(p: ^Parser) -> Maybe(^Node) {
	token, not_end := advance(p).?
	if !not_end {
		p.err = "expected expression"
		return nil
	}

	#partial switch token.typ {
	case .Wildcard:
		node := new(Node)
		node.typ = WildcardNode{}
		return node
	case .AnyDigit:
		node := new(Node)
		node.typ = AnyDigitNode{}
		return node
	case .AnyWordChar:
		node := new(Node)
		node.typ = AnyWordCharNode{}
		return node
	case .AnyWhitespace:
		node := new(Node)
		node.typ = AnyWhitespaceNode{}
		return node
	case .Literal:
		node := new(Node)
		node.typ = LiteralNode{char = token.rune}
		return node
	case .Lparen:
		node, ok := parse_concat(p).?
		if !ok do return nil
		if !consume(p, TokenTyp.Rparen) {
			free_node(node)
			p.err = "expected ')'"
			return nil
		}
		return node
	case .Lbracket:
		char_node := CharacterClassNode{}
		for current(p).typ != TokenTyp.Rbracket {
			tok, ok := advance(p).?
			if !ok {
				delete(char_node.matches)
				p.err = "expected ']'"
				return nil
			}
			if tok.typ != TokenTyp.Literal {
				delete(char_node.matches)
				p.err = "expected literal character in character class"
				return nil
			}
			append(&char_node.matches, tok.rune)
		}

		if !consume(p, TokenTyp.Rbracket) {
			delete(char_node.matches)
			p.err = "expected ']'"
			return nil
		}

		node := new(Node)
		node.typ = char_node
		return node
	case:
		p.err = "unexpected token"
		return nil
	}

	return nil
}
