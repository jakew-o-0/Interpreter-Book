package parser

import (
	"interpreter/ast"
	"interpreter/lexer"
	"interpreter/token"
	"strconv"
)

const (
    precidence_Lowest = iota
    precidence_Equals
    precidence_LessThan
    precidence_GreaterThan
    precidence_Sum
    precidence_Product
    precidence_Prefix
    precidence_Infix
);

var precidenceMap = map[uint32]int {
    token.Op_equal: precidence_Equals,
    token.Op_notEqual: precidence_Equals,
    token.Op_lessthan: precidence_LessThan,
    token.Op_greaterthan: precidence_GreaterThan,
    token.Op_plus: precidence_Sum,
    token.Op_minus: precidence_Sum,
    token.Op_asterisk: precidence_Product,
    token.Op_slash: precidence_Product,

}

type Parser struct {
    lex *lexer.Lexer       
    curToken token.Token
    nextToken token.Token
    ast []ast.Statement
    errors []string
}

func New(lex *lexer.Lexer) Parser {
    p := Parser {
        lex: lex,
    }
    p.Incr()
    p.Incr()
    return p
}

func (p *Parser) ParseTokens() {
    for p.curToken.TokenType != token.Eof {
        if node := p.parse(); node != nil {
            p.ast = append(p.ast, node)
        }
        p.Incr()
    }
}

func (p *Parser) parse() ast.Statement {
    switch p.curToken.TokenType {
        case token.Keyw_let: return p.parseLetStatement()
        case token.Keyw_return: return p.parseReturnStatement()
        default: return p.parseExpressionStatement()
    }
}

// parse statements {{{
func (p *Parser) parseLetStatement() ast.Statement {
    stmt := ast.LetStatement {
        Token: p.curToken,
    }
    p.Incr()

    // parse identifier
    stmt.Identifier = p.parseExpression(precidence_Lowest)
    if stmt.Identifier == nil {
        return nil
    } else {
        p.Incr()
    }

    // check syntax
    if !p.assert(token.Syn_assign, "invalid syntax: expected '='") {
        return nil
    }
    p.Incr()

    // parse expression
    stmt.Value = p.parseExpression(precidence_Lowest)
    if stmt.Value == nil {
        return nil
    } else {
        p.Incr()
    }

    // check syntax
    if !p.assert(token.Syn_semicolon, "invalid syntax: expected ';'") {
        return nil
    }
    return &stmt
}

func (p *Parser) parseReturnStatement() ast.Statement {
    stmt := ast.ReturnStatement {
        Token: p.curToken,
    }
    p.Incr()

    stmt.Value = p.parseExpression(precidence_Lowest)
    if stmt.Value == nil {
        return nil
    } else {
        p.Incr()
    }

    // check syntax
    if !p.assert(token.Syn_semicolon, "invalid syntax: expected ';'") {
        return nil
    }
    return &stmt
}

func (p *Parser) parseExpressionStatement() ast.Statement {
    stmt := ast.ExpressionStatement {
        Token: p.curToken,
    }

    stmt.Value = p.parseExpression(precidence_Lowest)
    if stmt.Value == nil {
        p.errors = append(p.errors, "could not parse expression")
        return nil
    }
    p.Incr()

    if !p.assert(token.Syn_semicolon, "invalid syntax: expected ';'") {
        return nil
    }
    return &stmt
}
// }}}

var indent int = 0
// parse expressions {{{
func (p *Parser) parseExpression(precidence int) ast.Expression {
    var leftExpr ast.Expression
    switch p.curToken.TokenType {
        case token.Type_identifier: leftExpr = p.parseIdentExpression()
        case token.Type_int: leftExpr = p.parseIntLiteral()
        case token.Type_bool: leftExpr = p.parseBoolLiteral()
        case token.Op_bang: leftExpr = p.parsePrefixExpression()
        case token.Op_minus: leftExpr = p.parsePrefixExpression()
        case token.Syn_lparen: leftExpr = p.parseParenExpr()
        default: leftExpr = nil
    }
    if leftExpr == nil {
        return nil
    }

    for p.curToken.TokenType != token.Eof && precidence < p.getPrecidence(p.nextToken.TokenType) {
        p.Incr()
        switch p.curToken.TokenType {
            case token.Op_plus: leftExpr = p.parseInfixExpression(leftExpr)
            case token.Op_minus: leftExpr = p.parseInfixExpression(leftExpr)
            case token.Op_asterisk: leftExpr = p.parseInfixExpression(leftExpr)
            case token.Op_slash: leftExpr = p.parseInfixExpression(leftExpr)
            case token.Op_lessthan: leftExpr = p.parseInfixExpression(leftExpr)
            case token.Op_greaterthan: leftExpr = p.parseInfixExpression(leftExpr)
            case token.Op_equal: leftExpr = p.parseInfixExpression(leftExpr)
            case token.Op_notEqual: leftExpr = p.parseInfixExpression(leftExpr)
            default: leftExpr = nil
        }
        if leftExpr == nil {
            return nil
        }

    }
    return leftExpr
}

func (p *Parser) parseIdentExpression() ast.Expression {
    return &ast.Identifier {
        Token: p.curToken,
        Value: p.curToken.Literal,
    }
}

func (p *Parser) parseIntLiteral() ast.Expression {
    expr := &ast.IntLiteral{
        Token: p.curToken,
    }
    if v,err := strconv.Atoi(p.curToken.Literal); err == nil {
        expr.Value = int64(v)
    } else {
        p.errors = append(p.errors, "Invalid int literal")
    }
    return expr
}

func (p *Parser) parseInfixExpression(left ast.Expression) ast.Expression {
    if left == nil {
        return nil
    }

    expr := ast.InfixExpression {
        Token: p.curToken,
        Opperator: p.curToken.Literal,
        Left: left,
    }
    prec := p.getPrecidence(p.curToken.TokenType)
    p.Incr()

    expr.Right = p.parseExpression(prec)
    if expr.Right == nil {
        return nil
    }
    return &expr
}

func (p *Parser) parsePrefixExpression() ast.Expression {
    expr := ast.PrefixExpression {
        Token: p.curToken,
        Opperator: p.curToken.Literal,
    }
    p.Incr()

    expr.Right = p.parseExpression(precidence_Prefix)
    if expr.Right == nil {
        return nil
    }
    return &expr
}

func (p *Parser) parseBoolLiteral() ast.Expression {
    expr := ast.BoolLiteral {
        Token: p.curToken,
    }
    b,err := strconv.ParseBool(p.curToken.Literal)
    if err != nil {
        p.errors = append(p.errors, "Invalid bool literal")
        return nil
    }
    expr.Value = b
    return &expr
}

func (p *Parser) parseParenExpr() ast.Expression {
    p.Incr()
    expr := p.parseExpression(precidence_Lowest)

    if expr == nil {
        p.errors = append(p.errors, "could not parse expression in parens")
        return nil
    }
    if p.nextToken.TokenType != token.Syn_rparen {
        p.errors = append(p.errors, "invalid syntax: expected ')'")
        return nil
    }
    p.Incr()
    return expr
}
//}}}



func (p *Parser) Incr() {
    p.curToken = p.nextToken
    p.nextToken = p.lex.NextToken()
}

func (p *Parser) assert(expected uint32, err string) bool {
    if p.curToken.TokenType == expected {
        return true
    }
    p.errors = append(p.errors, err)
    return false
}

func (p *Parser) getPrecidence(tok uint32) int {
    if pres,ok := precidenceMap[tok]; ok {
        return pres 
    }
    return precidence_Lowest
}
