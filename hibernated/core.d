module hibernated.core;

import std.ascii;
import std.exception;
import std.string;

import hibernated.annotations;
import hibernated.metadata;
import hibernated.type;

class HibernatedException : Exception {
    this(string msg, string f = __FILE__, size_t l = __LINE__) { super(msg, f, l); }
    this(Exception causedBy, string f = __FILE__, size_t l = __LINE__) { super(causedBy.msg, f, l); }
}

class SyntaxError : HibernatedException {
	this(string msg, string f = __FILE__, size_t l = __LINE__) { super(msg, f, l); }
}

class Query {
	EntityMetaData metadata;
	Token[] tokens;
	this(EntityMetaData metadata, string query) {
		this.metadata = metadata;
		tokens = tokenize(query.dup);
	}

}

enum KeywordType {
	NONE,
	SELECT,
	FROM,
	WHERE,
	ORDER,
	BY,
	ASC,
	DESC,
	JOIN,
	INNER,
	OUTER,
	LEFT,
	RIGHT,
	LIKE,
	IN,
	IS,
	NOT,
	NULL,
	AS,
	AND,
	OR,
	BETWEEN,
	DIV,
	MOD,
}

KeywordType isKeyword(string str) {
	return isKeyword(str.dup);
}

KeywordType isKeyword(char[] str) {
	char[] s = toUpper(str);
	if (s=="SELECT") return KeywordType.SELECT;
	if (s=="FROM") return KeywordType.FROM;
	if (s=="WHERE") return KeywordType.WHERE;
    if (s=="ORDER") return KeywordType.ORDER;
    if (s=="BY") return KeywordType.BY;
    if (s=="ASC") return KeywordType.ASC;
    if (s=="DESC") return KeywordType.DESC;
    if (s=="JOIN") return KeywordType.JOIN;
    if (s=="INNER") return KeywordType.INNER;
    if (s=="OUTER") return KeywordType.OUTER;
    if (s=="LEFT") return KeywordType.LEFT;
    if (s=="RIGHT") return KeywordType.RIGHT;
    if (s=="LIKE") return KeywordType.LIKE;
    if (s=="IN") return KeywordType.IN;
    if (s=="IS") return KeywordType.IS;
    if (s=="NOT") return KeywordType.NOT;
    if (s=="NULL") return KeywordType.NULL;
    if (s=="AS") return KeywordType.AS;
    if (s=="AND") return KeywordType.AND;
    if (s=="OR") return KeywordType.OR;
    if (s=="BETWEEN") return KeywordType.BETWEEN;
	if (s=="DIV") return KeywordType.DIV;
	if (s=="MOD") return KeywordType.MOD;
	return KeywordType.NONE;
}

unittest {
	assert(isKeyword("Null") == KeywordType.NULL);
	assert(isKeyword("from") == KeywordType.FROM);
	assert(isKeyword("SELECT") == KeywordType.SELECT);
	assert(isKeyword("blabla") == KeywordType.NONE);
}

enum OperatorType {
	NONE,
	EQ, // ==
	NE, // != <>
	LT, // <
	GT, // >
	LE, // <=
	GE, // >=
	MUL,// *
	ADD,// +
	SUB,// -
	DIV,// /
}

OperatorType isOperator(char[] s, ref int i) {
	int len = cast(int)s.length;
	char ch = s[i];
	char ch2 = i < len - 1 ? s[i + 1] : 0;
	//char ch3 = i < len - 2 ? s[i + 2] : 0;
	if (ch == '=' && ch2 == '=') { i++; return OperatorType.EQ; } // ==
	if (ch == '!' && ch2 == '=') { i++; return OperatorType.NE; } // !=
	if (ch == '<' && ch2 == '>') { i++; return OperatorType.NE; } // <>
	if (ch == '<' && ch2 == '=') { i++; return OperatorType.LE; } // <=
	if (ch == '>' && ch2 == '=') { i++; return OperatorType.GE; } // >=
	if (ch == '=') return OperatorType.EQ; // =
	if (ch == '<') return OperatorType.LT; // <
	if (ch == '>') return OperatorType.GT; // <
	if (ch == '*') return OperatorType.MUL; // <
	if (ch == '+') return OperatorType.ADD; // <
	if (ch == '-') return OperatorType.SUB; // <
	if (ch == '/') return OperatorType.DIV; // <
	return OperatorType.NONE;
}


enum TokenType {
	Keyword,      // WHERE
	Ident,        // ident
	Number,       // 25   13.5e-10
	String,       // 'string'
	Operator,     // == != <= >= < > + - * /
	Dot,          // .
	OpenBracket,  // (
	CloseBracket, // )
}

class Token {
	TokenType type;
	KeywordType keyword = KeywordType.NONE;
	OperatorType operator = OperatorType.NONE;
	char[] text;
	char[] spaceAfter;
	this(TokenType type, string text) {
		this.type = type;
		this.text = text.dup;
	}
	this(TokenType type, char[] text) {
		this.type = type;
		this.text = text;
	}
	this(KeywordType keyword, char[] text) {
		this.type = TokenType.Keyword;
		this.keyword = keyword;
		this.text = text;
	}
	this(OperatorType op, char[] text) {
		this.type = TokenType.Operator;
		this.operator = op;
		this.text = text;
	}
}

Token[] tokenize(string s) {
	return tokenize(s.dup);
}

Token[] tokenize(char[] s) {
	Token[] res;
	int startpos = 0;
	int state = 0;
	int len = cast(int)s.length;
	for (int i=0; i<len; i++) {
		char ch = s[i];
		char ch2 = i < len - 1 ? s[i + 1] : 0;
		char ch3 = i < len - 2 ? s[i + 2] : 0;
		char[] text;
		bool quotedIdent = ch == '`';
		startpos = i;
		OperatorType op = isOperator(s, i);
		if (op != OperatorType.NONE) {
			// operator
			res ~= new Token(op, s[startpos .. i + 1]);
		} else if (isAlpha(ch) || ch=='_' || quotedIdent) {
			// identifier or keyword
			if (quotedIdent) {
				i++;
				enforceEx!SyntaxError(i < len - 1, "Invalid quoted identifier near " ~ cast(string)s[startpos .. $]);
			}
			// && state == 0
			for(int j=i; j<len; j++) {
				if (isAlphaNum(s[j])) {
					text ~= s[j];
					i = j;
				} else {
					break;
				}
			}
			enforceEx!SyntaxError(text.length > 0, "Invalid quoted identifier near " ~ cast(string)s[startpos .. $]);
			if (quotedIdent) {
				enforceEx!SyntaxError(i < len - 1 && s[i + 1] == '`', "Invalid quoted identifier near " ~ cast(string)s[startpos .. $]);
				i++;
			}
			KeywordType keywordId = isKeyword(text);
			if (keywordId != KeywordType.NONE && !quotedIdent)
				res ~= new Token(keywordId, text);
			else
				res ~= new Token(TokenType.Ident, text);
		} else if (isWhite(ch)) {
			// whitespace
			for(int j=i; j<len; j++) {
				if (isWhite(s[j])) {
					text ~= s[j];
					i = j;
				} else {
					break;
				}
			}
			// don't add whitespace to lexer results as separate token
			// add as spaceAfter
			if (res.length > 0) {
				res[$ - 1].spaceAfter = text;
			}
		} else if (ch == '\'') {
			// string constant
			i++;
			for(int j=i; j<len; j++) {
				if (s[j] != '\'') {
					text ~= s[j];
					i = j;
				} else {
					break;
				}
			}
			enforceEx!SyntaxError(i < len - 1 && s[i + 1] == '\'', "Unfinished string near " ~ cast(string)s[startpos .. $]);
			i++;
			res ~= new Token(TokenType.String, text);
		} else if (isDigit(ch) || (ch == '.' && isDigit(ch2))) {
			// numeric constant
			if (ch == '.') {
				// .25
				text ~= '.';
				i++;
				for(int j = i; j<len; j++) {
					if (isDigit(s[j])) {
						text ~= s[j];
						i = j;
					} else {
						break;
					}
				}
			} else {
				// 123
				for(int j=i; j<len; j++) {
					if (isDigit(s[j])) {
						text ~= s[j];
						i = j;
					} else {
						break;
					}
				}
				// .25
				if (i < len - 1 && s[i + 1] == '.') {
					text ~= '.';
					i++;
					for(int j = i; j<len; j++) {
						if (isDigit(s[j])) {
							text ~= s[j];
							i = j;
						} else {
							break;
						}
					}
				}
			}
			if (i < len - 1 && toLower(s[i + 1]) == 'e') {
				text ~= s[i+1];
				i++;
				if (i < len - 1 && (s[i + 1] == '-' || s[i + 1] == '+')) {
					text ~= s[i+1];
					i++;
				}
				enforceEx!SyntaxError(i < len - 1 && isDigit(s[i]), "Invalid number near " ~ cast(string)s[startpos .. $]);
				for(int j = i; j<len; j++) {
					if (isDigit(s[j])) {
						text ~= s[j];
						i = j;
					} else {
						break;
					}
				}
			}
			enforceEx!SyntaxError(i >= len - 1 || !isAlpha(s[i]), "Invalid number near " ~ cast(string)s[startpos .. $]);
			res ~= new Token(TokenType.Number, text);
		} else if (ch == '.') {
			res ~= new Token(TokenType.Dot, ".");
		} else if (ch == '(') {
			res ~= new Token(TokenType.OpenBracket, "(");
		} else if (ch == ')') {
			res ~= new Token(TokenType.CloseBracket, ")");
		} else {
			enforceEx!SyntaxError(false, "Invalid token near " ~ cast(string)s[startpos .. $]);
		}
	}
	return res;
}

unittest {
	Token[] tokens;
	tokens = tokenize("SELECT a From User a where a.flags = 1 AND a.name='john' ORDER BY a.idx ASC");
	assert(tokens.length == 23);
	assert(tokens[0].type == TokenType.Keyword);
	assert(tokens[2].type == TokenType.Keyword);
	assert(tokens[5].type == TokenType.Keyword);
	assert(tokens[5].text == "where");
	assert(tokens[16].type == TokenType.String);
	assert(tokens[16].text == "john");
}
