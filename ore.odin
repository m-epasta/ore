package ore

Error :: string

matches :: proc(input: string, pattern: string) -> (ok: bool, err: Error) {
	parser := tokenize(pattern)
	if parser.err != "" {
		delete(parser.tokens)
		return false, parser.err
	}

	ast, ast_ok := parse(&parser).?
	if !ast_ok {
		if parser.err != "" {
			delete(parser.tokens)
			return false, parser.err
		}
		delete(parser.tokens)
		return false, "unknown parse error"
	}

	result := match(ast, input)
	delete(parser.tokens)
	return result, ""
}
