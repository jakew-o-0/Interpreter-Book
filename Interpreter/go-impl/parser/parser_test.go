package parser

import (
	"interpreter/lexer"
	"testing"
)

func TestLetStatements(t *testing.T) {
    input := "let a = 10; let b = 2; let c = 5;"
    tests := []string {
        "let stmt:: ident:a value:10",
        "let stmt:: ident:b value:2",
        "let stmt:: ident:c value:5",
    }

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for _,e := range p.errors {
        println(e)
    }
    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:'%s', got:'%s'", tests[i], node.ToString())
        }
    }
}

func TestReturnStatements(t *testing.T) {
    input := "return 5; return 10; return 993322;";
    tests := []string {
        "return stmt:: value:5",
        "return stmt:: value:10",
        "return stmt:: value:993322",
    }

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:'%s', got:'%s'", tests[i], node.ToString())
        }
    }
}

func TestIntLiteralExpressions(t *testing.T) {
    input := "5;";
    test := "expression stmt:: value:5"

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    node := p.ast[0]
    for _,e := range p.errors {
        println(e)
    }
    if node.ToString() != test {
        t.Fatalf("Expected:'%s', got:'%s'", test, node.ToString())
    }

}

func TestPrefixExpressions(t *testing.T) {
    input := "-5; !asdf";
    tests := []string {
        "expression stmt:: value:opperator:- right:5",
        "expression stmt:: value:opperator:! right:asdf",
    }

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:'%s', got:'%s'", tests[i], node.ToString())
        }
    }
}

func TestInfixExpressions(t *testing.T) {
    input := "5 + 5; 5 - 5; 5 / 5; 5 * 5; 5 < 5; 5 > 5; 5 == 5; 5 != 5;"
    tests := []string {
        "expression stmt:: value:left:5 opperator:+ right:5",
        "expression stmt:: value:left:5 opperator:- right:5",
        "expression stmt:: value:left:5 opperator:/ right:5",
        "expression stmt:: value:left:5 opperator:* right:5",
        "expression stmt:: value:left:5 opperator:< right:5",
        "expression stmt:: value:left:5 opperator:> right:5",
        "expression stmt:: value:left:5 opperator:== right:5",
        "expression stmt:: value:left:5 opperator:!= right:5",
    }

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:'%s', got:'%s'", tests[i], node.ToString())
        }
    }
}
