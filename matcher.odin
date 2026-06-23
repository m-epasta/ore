#+private
package ore

import "core:c/libc"
import "core:slice"

Matcher :: struct {
	pos:             uintptr,
	input:           string,
	groups:          [MAX_CAPTURE_GROUPS]GroupRange,
	open_groups:     [dynamic]int,
	backtrack_stack: [dynamic]MatcherSnapshot,
}

match :: proc(ast: ^Node, input: string) -> bool {
	for i in 0 ..< len(input) {
		matcher := new(Matcher, context.temp_allocator)
		matcher.input = input
		matcher.pos = uintptr(i)
		for &g in matcher.groups {
			g.start = UNSET_GROUP
			g.end = UNSET_GROUP
		}
		matcher.open_groups = make([dynamic]int, context.temp_allocator)
		matcher.backtrack_stack = make([dynamic]MatcherSnapshot, context.temp_allocator)

		if match_node(matcher, ast) do return true
	}

	return false
}

match_node :: proc(matcher: ^Matcher, node: ^Node) -> bool {
	switch &typ in node.typ {
	case WildcardNode:
		return matchWildcardNode(matcher, &typ)
	case LiteralNode:
		return matchLiteralNode(matcher, &typ)
	case AnchorNode:
		return matchAnchorNode(matcher, &typ)
	case AnyDigitNode:
		return matchAnyDigitNode(matcher, &typ)
	case AnyWordCharNode:
		return matchAnyWordCharNode(matcher, &typ)
	case AnyWhitespaceNode:
		return matchAnyWhitespaceNode(matcher, &typ)
	case CharacterClassNode:
		return matchCharacterClassNode(matcher, &typ)
	case EveythingButDigitNode:
		return matchEverythingButDigitNode(matcher, &typ)
	case EverythingButWhitespaceNode:
		return matchEverythingButWhitespaceNode(matcher, &typ)
	case EverythingButWordCharNode:
		return matchEverythingButWordCharNode(matcher, &typ)
	case PlusNode:
		return matchPlusNode(matcher, &typ)
	case StarNode:
		return matchStarNode(matcher, &typ)
	case QuestionNode:
		return matchQuestionNode(matcher, &typ)
	case RangeRepNode:
		return matchRangeRepNode(matcher, &typ)
	case CaptureNode:
		return matchCaptureNode(matcher, &typ)
	case BackrefNode:
		return matchBackrefNode(matcher, &typ)
	case ConcatNode:
		return matchConcatNode(matcher, &typ)
	case AlternationNode:
		return matchAlternationNode(matcher, &typ)
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

matchAnchorNode :: proc(matcher: ^Matcher, node: ^AnchorNode) -> bool {
	switch {
	case node.start && !node.end:
		return matchStartAnchor(matcher, node)
	case node.end:
		return matchEndAnchor(matcher, node)
	case:
		// An anchor has to be either start or end
		break
	}

	return false
}

matchStartAnchor :: proc(matcher: ^Matcher, node: ^AnchorNode) -> bool {
	if is_at_end(matcher) do return false

	return matcher.pos == 0
}

matchEndAnchor :: proc(matcher: ^Matcher, node: ^AnchorNode) -> bool {
	return is_at_end(matcher)
}

matchAnyDigitNode :: proc(matcher: ^Matcher, node: ^AnyDigitNode) -> bool {
	if is_at_end(matcher) || libc.isdigit(cast(i32)current(matcher)) == 0 do return false

	advance(matcher)
	return true
}

matchAnyWhitespaceNode :: proc(matcher: ^Matcher, node: ^AnyWhitespaceNode) -> bool {
	if is_at_end(matcher) || libc.isspace(cast(i32)current(matcher)) == 0 do return false

	advance(matcher)
	return true
}

matchAnyWordCharNode :: proc(matcher: ^Matcher, node: ^AnyWordCharNode) -> bool {
	if is_at_end(matcher) do return false
	c := current(matcher)
	if libc.isalpha(cast(i32)c) == 0 && c != '_' do return false

	advance(matcher)
	return true
}

matchCharacterClassNode :: proc(matcher: ^Matcher, node: ^CharacterClassNode) -> bool {
	if node.neg == true {
		if is_at_end(matcher) || slice.contains(node.matches[:], current(matcher)) do return false
	} else {
		if is_at_end(matcher) || !slice.contains(node.matches[:], current(matcher)) do return false
	}

	advance(matcher)
	return true
}

matchEverythingButDigitNode :: proc(matcher: ^Matcher, node: ^EveythingButDigitNode) -> bool {
	if is_at_end(matcher) || libc.isdigit(cast(i32)current(matcher)) != 0 do return false

	advance(matcher)
	return true
}

matchEverythingButWhitespaceNode :: proc(
	matcher: ^Matcher,
	node: ^EverythingButWhitespaceNode,
) -> bool {
	if is_at_end(matcher) || libc.isspace(cast(i32)current(matcher)) != 0 do return false

	advance(matcher)
	return true
}

matchEverythingButWordCharNode :: proc(
	matcher: ^Matcher,
	node: ^EverythingButWordCharNode,
) -> bool {
	if is_at_end(matcher) do return false
	c := current(matcher)
	if libc.isalpha(cast(i32)c) != 0 || c == '_' do return false

	advance(matcher)
	return true
}

matchPlusNode :: proc(matcher: ^Matcher, node: ^PlusNode) -> bool {
	if !match_node(matcher, node.child) do return false

	for {
		snap := snapshot_matcher(matcher)
		if !match_node(matcher, node.child) do break
		append(&matcher.backtrack_stack, snap)
	}
	return true
}

matchStarNode :: proc(matcher: ^Matcher, node: ^StarNode) -> bool {
	for {
		snap := snapshot_matcher(matcher)
		if !match_node(matcher, node.child) do break
		append(&matcher.backtrack_stack, snap)
	}
	return true
}

matchQuestionNode :: proc(matcher: ^Matcher, node: ^QuestionNode) -> bool {
	snap := snapshot_matcher(matcher)
	if match_node(matcher, node.child) do append(&matcher.backtrack_stack, snap)
	return true
}

matchRangeRepNode :: proc(matcher: ^Matcher, node: ^RangeRepNode) -> bool {
	for _ in 0 ..< node.from do if !match_node(matcher, node.child) do return false


	if node.to > 0 {
		for _ in node.from ..< node.to {
			snap := snapshot_matcher(matcher)
			if !match_node(matcher, node.child) do break
			append(&matcher.backtrack_stack, snap)
		}
	} else {
		for {
			snap := snapshot_matcher(matcher)
			if !match_node(matcher, node.child) do break
			append(&matcher.backtrack_stack, snap)
		}
	}
	return true
}

matchCaptureNode :: proc(matcher: ^Matcher, node: ^CaptureNode) -> bool {
	mark := len(matcher.backtrack_stack)
	old_start := matcher.groups[node.id].start
	old_end := matcher.groups[node.id].end

	matcher.groups[node.id].start = matcher.pos
	matcher.groups[node.id].end = matcher.pos
	append(&matcher.open_groups, node.id)

	if match_node(matcher, node.child) {
		pop(&matcher.open_groups)
		matcher.groups[node.id].end = matcher.pos
		return true
	}

	pop(&matcher.open_groups)
	matcher.groups[node.id].start = old_start
	matcher.groups[node.id].end = old_end
	resize(&matcher.backtrack_stack, mark)
	return false
}

matchBackrefNode :: proc(matcher: ^Matcher, node: ^BackrefNode) -> bool {
	id := node.id
	if id >= MAX_CAPTURE_GROUPS do return false

	gr := matcher.groups[id]
	if gr.start == UNSET_GROUP || gr.end == UNSET_GROUP do return false
	if gr.end < gr.start do return false

	cap_len := int(gr.end - gr.start)
	cap_input := matcher.input[gr.start:gr.end]

	if cast(int)matcher.pos + cap_len > len(matcher.input) do return false

	if matcher.input[matcher.pos:matcher.pos + uintptr(cap_len)] == cap_input {
		matcher.pos += uintptr(cap_len)
		return true
	}

	return false
}

matchConcatNode :: proc(matcher: ^Matcher, node: ^ConcatNode) -> bool {
	mark := len(matcher.backtrack_stack)

	if !match_node(matcher, node.left) do return false

	for {
		if match_node(matcher, node.right) do return true

		if len(matcher.backtrack_stack) == mark {
			return false
		}

		restore_matcher(matcher, pop(&matcher.backtrack_stack))
	}
}

matchAlternationNode :: proc(matcher: ^Matcher, node: ^AlternationNode) -> bool {
	for i in 0 ..< len(node.exprs) {
		mark := len(matcher.backtrack_stack)
		snap := snapshot_matcher(matcher)

		if match_node(matcher, node.exprs[i]) {
			if i + 1 < len(node.exprs) do append(&matcher.backtrack_stack, snap)
			return true
		}

		resize(&matcher.backtrack_stack, mark)
	}
	return false
}
