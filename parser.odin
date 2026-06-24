#+private
package ore

import "core:c/libc"
import "core:strings"

Parser :: struct {
	current:     uintptr,
	tokens:      [dynamic]Token,
	err:         Error,
	group_count: int,
}

parse :: proc(p: ^Parser) -> Maybe(^Node) {
	node, alt_ok := parse_alternation(p).?
	if !alt_ok do return nil

	if current(p).typ != TokenTyp.End {
		p.err = "unexpected token after expression"
		return nil
	}

	return node
}

parse_alternation :: proc(p: ^Parser) -> Maybe(^Node) {
	left, ok := parse_concat(p).?
	if !ok do return nil

	if current(p).typ != TokenTyp.Pipe do return left

	exprs := make([dynamic]^Node, context.temp_allocator)
	append(&exprs, left)

	for current(p).typ == TokenTyp.Pipe {
		if !consume(p, TokenTyp.Pipe) do return nil
		right, right_ok := parse_concat(p).?
		if !right_ok do return nil
		append(&exprs, right)
	}

	node := new(Node, context.temp_allocator)
	node.typ = AlternationNode {
		exprs = exprs,
	}
	return node
}

parse_concat :: proc(p: ^Parser) -> Maybe(^Node) {
	left, ok := parse_factor(p).?
	if !ok do return nil

	if !is_at_end(p) &&
	   current(p).typ != TokenTyp.Rparen &&
	   current(p).typ != TokenTyp.Rbracket &&
	   current(p).typ != TokenTyp.Pipe {
		right, right_ok := parse_concat(p).?
		if !right_ok do return nil

		node := new(Node, context.temp_allocator)
		node.typ = ConcatNode {
			left  = left,
			right = right,
		}
		return node
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
			node := new(Node, context.temp_allocator)
			node.typ = PlusNode {
				child = child,
			}
			child = node
		case .Star:
			if !consume(p, TokenTyp.Star) do return nil
			node := new(Node, context.temp_allocator)
			node.typ = StarNode {
				child = child,
			}
			child = node
		case .Question:
			if !consume(p, TokenTyp.Question) do return nil
			node := new(Node, context.temp_allocator)
			node.typ = QuestionNode {
				child = child,
			}
			child = node
		case .Lbrace:
			if !consume(p, TokenTyp.Lbrace) do return nil

			range_rep := RangeRepNode {
				child = child,
				from  = 0,
				to    = 0,
			}

			if current(p).typ == TokenTyp.Literal {
				r := current(p).rune
				if isdigit(r) {
					range_rep.from = int(r - '0')
					advance(p)
				}
			}

			if current(p).typ == TokenTyp.Comma {
				consume(p, TokenTyp.Comma)
				if current(p).typ == TokenTyp.Literal {
					r := current(p).rune
					if isdigit(r) {
						range_rep.to = int(r - '0')
						advance(p)
					}
				}
			} else {
				range_rep.to = range_rep.from
			}

			if !consume(p, TokenTyp.Rbrace) {
				p.err = "expected '}'"
				return nil
			}

			node := new(Node, context.temp_allocator)
			node.typ = range_rep
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
		node := new(Node, context.temp_allocator)
		node.typ = WildcardNode{}
		return node
	case .Caret:
		node := new(Node, context.temp_allocator)
		node.typ = AnchorNode {
			start = true,
		}
		return node
	case .Dollar:
		node := new(Node, context.temp_allocator)
		node.typ = AnchorNode {
			end = true,
		}
		return node
	case .AnyDigit:
		node := new(Node, context.temp_allocator)
		node.typ = AnyDigitNode{}
		return node
	case .AnyWordChar:
		node := new(Node, context.temp_allocator)
		node.typ = AnyWordCharNode{}
		return node
	case .AnyWhitespace:
		node := new(Node, context.temp_allocator)
		node.typ = AnyWhitespaceNode{}
		return node
	case .EverythingButDigit:
		node := new(Node, context.temp_allocator)
		node.typ = EveythingButDigitNode{}
		return node
	case .EverythingButWhitespace:
		node := new(Node, context.temp_allocator)
		node.typ = EverythingButWhitespaceNode{}
		return node
	case .EverythingButWordChar:
		node := new(Node, context.temp_allocator)
		node.typ = EverythingButWordCharNode{}
		return node
	case .Literal:
		node := new(Node, context.temp_allocator)
		node.typ = LiteralNode {
			char = token.rune,
		}
		return node
	case .Lparen:
		group_id := p.group_count
		p.group_count += 1
		inner, ok := parse_alternation(p).?
		if !ok do return nil
		if !consume(p, TokenTyp.Rparen) {
			p.err = "expected ')'"
			return nil
		}
		node := new(Node, context.temp_allocator)
		node.typ = CaptureNode {
			id    = group_id,
			child = inner,
		}
		return node
	case .Lbracket:
		char_node := CharacterClassNode {
			neg     = false,
			matches = make([dynamic]rune, context.temp_allocator),
		}
		for current(p).typ != TokenTyp.Rbracket {
			tok, ok := advance(p).?
			if !ok {
				delete(char_node.matches)
				p.err = "expected ']'"
				return nil
			}
			#partial switch tok.typ {
			case .Lbracket:
				if current(p).typ == TokenTyp.Colon {
					// Part of [: POSIX class opening
				} else {
					append(&char_node.matches, tok.rune)
				}
			case .Caret:
				if len(char_node.matches) == 0 do char_node.neg = true
				else do append(&char_node.matches, tok.rune)
			case .Literal:
				append(&char_node.matches, tok.rune)
			case .Dash:
				prev := p.tokens[p.current - 2]
				if prev.typ != TokenTyp.Literal {
					p.err = "expected a literal before range declaration because of spotted '-' in a class"
					return nil
				}

				next, next_ok := advance(p).?
				if !next_ok {
					p.err = "expected a literal after '-'"
					return nil
				}

				switch {
				case (isdigit(prev.rune) && isdigit(next.rune)) ||
				     (isalpha(prev.rune) && isalpha(next.rune)):
					for r := prev.rune; r <= next.rune; r += 1 {
						append(&char_node.matches, r)
					}
				case:
					p.err = "both range bounds should be of same type"
					return nil
				}
			case .Colon:
				pclass: string
				builder: strings.Builder
				strings.builder_init(&builder, context.temp_allocator)
				for current(p).typ != TokenTyp.Colon {
					if !isalpha(current(p).rune) {
						p.err = "Expected letter in between posix class delimeter"
						return nil
					}
					strings.write_rune(&builder, current(p).rune)
					if !consume(p, TokenTyp.Literal) do return nil
				}
				pclass = strings.to_string(builder)

				if !consume(p, TokenTyp.Colon) do return nil

				switch pclass {
				case "alpha":
					for r := 'a'; r <= 'z'; r += 1 do append(&char_node.matches, r)
					for r := 'A'; r <= 'Z'; r += 1 do append(&char_node.matches, r)
				case "alnum":
					for r := '0'; r <= '9'; r += 1 do append(&char_node.matches, r)
					for r := 'a'; r <= 'z'; r += 1 do append(&char_node.matches, r)
					for r := 'A'; r <= 'Z'; r += 1 do append(&char_node.matches, r)
				case "digit":
					for r := '0'; r <= '9'; r += 1 do append(&char_node.matches, r)
				case "xdigit":
					for r := '0'; r <= '9'; r += 1 do append(&char_node.matches, r)
					for r := 'a'; r <= 'f'; r += 1 do append(&char_node.matches, r)
					for r := 'A'; r <= 'F'; r += 1 do append(&char_node.matches, r)
				case "lower":
					for r := 'a'; r <= 'z'; r += 1 do append(&char_node.matches, r)
				case "upper":
					for r := 'A'; r <= 'Z'; r += 1 do append(&char_node.matches, r)
				case "punct":
					for r in "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" do append(&char_node.matches, r)
				case "space":
					for r in "\t\n\v\f\r " do append(&char_node.matches, r)
				case "blank":
					append(&char_node.matches, ' ')
					append(&char_node.matches, '\t')
				case "cntrl":
					for r := 0x00; r <= 0x1F; r += 1 do append(&char_node.matches, rune(r))
					append(&char_node.matches, rune(0x7F))
				case "print":
					for r := ' '; r <= '~'; r += 1 do append(&char_node.matches, r)
				case "graph":
					for r := '!'; r <= '~'; r += 1 do append(&char_node.matches, r)
				case:
					delete(char_node.matches)
					p.err = strings.concatenate(
						{"unknown posix class: ", pclass},
						context.temp_allocator,
					)
					return nil
				}

				if !consume(p, TokenTyp.Rbracket) {
					delete(char_node.matches)
					p.err = "expected ']' after posix class"
					return nil
				}
			case:
				delete(char_node.matches)
				p.err = "expected literal character in character class"
				return nil
			}
		}

		if !consume(p, TokenTyp.Rbracket) {
			delete(char_node.matches)
			p.err = "expected ']'"
			return nil
		}

		node := new(Node, context.temp_allocator)
		node.typ = char_node
		return node
	case .Lbrace:
		p.err = "unexpected '{' without preceding expression"
		return nil
	case .BackRefIdx:
		idx := int(token.rune - '0')
		node := new(Node, context.temp_allocator)
		node.typ = BackrefNode {
			id = idx,
		}
		return node
	case:
		p.err = "unexpected token"
		return nil
	}

	return nil
}
