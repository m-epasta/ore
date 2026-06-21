package ore

matches :: proc(input: string, pattern: string) -> Maybe(bool) {
	parser := tokenize(pattern)
	ast, ast_ok := parse(&parser).?
	if !ast_ok do return nil

	return match(&ast, input)
}
