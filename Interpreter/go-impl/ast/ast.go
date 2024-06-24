package ast

import (
	"fmt"
	"interpreter/token"
)

type Statement interface {
    statementInf()
    ToString() string
}

type Expression interface {
    expressionInf()
    ToString() string
}


// Statements {{{
type LetStatement struct {
    Token token.Token
    Identifier Expression
    Value Expression
}
func(l *LetStatement) statementInf() {}
func (l *LetStatement) ToString() string { 
    return fmt.Sprintf(
        "let stmt:: ident:%s value:%s",
        l.Identifier.ToString(),
        l.Value.ToString(),
    )
}

type ReturnStatement struct {
    Token token.Token
    Value Expression
}
func(l *ReturnStatement) statementInf() {}
func (l *ReturnStatement) ToString() string { 
    return fmt.Sprintf(
        "return stmt:: value:%s",
        l.Value.ToString(),
    )
}

type ExpressionStatement struct {
    Token token.Token
    Value Expression
}
func(l *ExpressionStatement) statementInf() {}
func (l *ExpressionStatement) ToString() string { 
    return fmt.Sprintf(
        "expression stmt:: value:%s",
        l.Value.ToString(),
    )
}
//}}}

// Expressions {{{
type Identifier struct {
    Token token.Token
    Value string
}
func (i *Identifier) expressionInf() {}
func (i *Identifier) ToString() string {
    return i.Value 
}

type IntLiteral struct {
    Token token.Token
    Value int64
}
func (i *IntLiteral) expressionInf() {}
func (i *IntLiteral) ToString() string {
    return fmt.Sprintf("%d", i.Value)
}

type PrefixExpression struct {
    Token token.Token
    Opperator string
    Right Expression
}
func (p *PrefixExpression) expressionInf() {}
func (p *PrefixExpression) ToString() string {
    return fmt.Sprintf("opperator:%s right:%s", p.Opperator, p.Right.ToString())
}

type InfixExpression struct {
    Token token.Token
    Opperator string
    Left Expression
    Right Expression
}
func (i *InfixExpression) expressionInf() {}
func (i *InfixExpression) ToString() string {
    return fmt.Sprintf("left:%s opperator:%s right:%s", i.Left.ToString(), i.Opperator, i.Right.ToString())
}
//}}}
