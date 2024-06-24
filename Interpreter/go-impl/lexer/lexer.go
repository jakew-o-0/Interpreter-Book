package lexer

import (
	"interpreter/token"
)

type Lexer struct {
    src []byte
    ch byte
    cur_pos uint32
    next_pos uint32
}

func New(src []byte) Lexer {
    l := Lexer{
        src: src,
        ch: 0,
        cur_pos: 0,
        next_pos: 0,
    }
    l.Incr()
    return l
}

func (l *Lexer) Incr() {
    l.cur_pos = l.next_pos
    l.next_pos++
    if int(l.cur_pos) >= len(l.src){
        l.ch = 0
        return
    }
    l.ch = l.src[l.cur_pos]
}
func (l *Lexer) decr() {
    l.next_pos = l.cur_pos
    l.cur_pos--
    l.ch = l.src[l.cur_pos]
}

func (l *Lexer) peekAssert(expected byte) bool {
    if l.src[l.next_pos] == expected {
        return true
    }
    return false
}

func (l *Lexer) isLetter() bool {
    if l.ch >= 'a' && 'z' >= l.ch || l.ch >= 'A' && 'Z' >= l.ch {
        return true
    }
    return false
}
func (l *Lexer) getWord() string {
    start := l.cur_pos
    for l.isLetter() { l.Incr() }
    s := string(l.src[start:l.cur_pos])
    l.decr()
    return s
}

func (l *Lexer) isNum() bool {
    if '0' <= l.ch && '9' >= l.ch {
        return true
    }
    return false
}
func (l *Lexer) getNum() string {
    start := l.cur_pos
    for l.isNum() { l.Incr() }
    s := string(l.src[start:l.cur_pos])
    l.decr()
    return s
}

func (l *Lexer) isWhitespace() bool {
    if l.ch == ' ' || l.ch == '\t' || l.ch == '\n'|| l.ch == '\r' {
        return true
    }
    return false
}
func (l *Lexer) consumeWhitespace() {
    for l.isWhitespace() {
        l.Incr()
    }
}

func (l *Lexer) NextToken() token.Token {
    l.consumeWhitespace()
    tok := token.NewToken()
    switch l.ch {
        case '+': tok.SetToken("+", token.Op_plus) 
        case '-': tok.SetToken("-", token.Op_minus)
        case '*': tok.SetToken("*", token.Op_asterisk)
        case '/': tok.SetToken("/", token.Op_slash)
        case '{': tok.SetToken("{", token.Syn_lbrace)
        case '}': tok.SetToken("}", token.Syn_rbrace)
        case '(': tok.SetToken("(", token.Syn_lparen)
        case ')': tok.SetToken(")", token.Syn_rparen)
        case '<': tok.SetToken("<", token.Op_lessthan)
        case '>': tok.SetToken(">", token.Op_greaterthan)
        case ';': tok.SetToken(";", token.Syn_semicolon)
        case ',': tok.SetToken(",", token.Syn_comma)
        case 0: tok.SetToken("", token.Eof)

        case '=':{
            if l.peekAssert('=') {
                tok.SetToken("==", token.Op_equal)
                l.Incr()
            } else {
                tok.SetToken("=", token.Syn_assign)
            }
        }
        case '!':{
            if l.peekAssert('=') {
                tok.SetToken("!=", token.Op_notEqual)
                l.Incr()
            } else {
                tok.SetToken("!", token.Op_bang)
            }
        }

        default:{
            if l.isLetter() {
                tok.SetWord(l.getWord())
            } else if l.isNum() {
                tok.SetToken(l.getNum(), token.Type_int)
            } else {
                tok.SetToken("", token.Illegal)
            }
        }
    }
    l.Incr()
    return tok
}
