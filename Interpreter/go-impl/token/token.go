package token

const (
    Keyw_let uint32 = iota
    Keyw_return
    Keyw_fn
    Keyw_if
    Keyw_else

    Syn_semicolon
    Syn_comma
    Syn_assign
    Syn_lparen
    Syn_rparen
    Syn_lbrace
    Syn_rbrace

    Op_plus
    Op_minus
    Op_slash
    Op_asterisk
    Op_bang
    Op_equal
    Op_notEqual
    Op_lessthan
    Op_greaterthan

    Type_int
    Type_bool
    Type_identifier

    Eof
    Illegal
)

type Token struct {
    Literal string
    TokenType uint32
}
func NewToken() Token {
    return Token{}
}

func (t *Token)SetToken(lit string, tType uint32) {
    t.Literal = lit
    t.TokenType = tType
}
func (t *Token) SetWord(lit string) {
    t.Literal = lit
    if typ,ok := keywords[lit]; ok {
        t.TokenType = typ
    } else {
        t.TokenType = Type_identifier
    }
}

var keywords = map[string]uint32 {
    "let": Keyw_let,
    "return": Keyw_return,
    "fn": Keyw_fn,
    "if": Keyw_if,
    "else": Keyw_else,
    "true": Type_bool,
    "false": Type_bool,
}
