package ore

Error :: string

matches :: proc(
	input: string,
	pattern: string,
	unicode_mode: bool = false,
) -> (
	ok: bool,
	err: Error,
) {
	flag := unicode_mode
	parser := tokenize(pattern, flag)
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

	result := match(ast, input, flag)
	delete(parser.tokens)
	return result, ""
}
