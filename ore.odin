package ore

matches :: proc(input: string, match: string) -> Maybe(bool) {
	parser := tokenize(match)
	ast, ast_ok := parse(&parser).?
	if !ast_ok do return nil

	return true
}
