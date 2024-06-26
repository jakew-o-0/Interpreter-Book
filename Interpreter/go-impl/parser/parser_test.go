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

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:'%s', got:'%s'", tests[i], node.ToString())
        }
    }
    if len(p.errors) > 0 {
        for _,e := range p.errors {
            println(e)
        }
        t.Fatal()
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
    if len(p.errors) > 0 {
        for _,e := range p.errors {
            println(e)
        }
        t.Fatal()
    }
}

func TestIntLiteralExpressions(t *testing.T) {
    input := "5;";
    test := "expression stmt:: value:5"

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    node := p.ast[0]
    if node.ToString() != test {
        t.Fatalf("Expected:'%s', got:'%s'", test, node.ToString())
    }
    if len(p.errors) > 0 {
        for _,e := range p.errors {
            println(e)
        }
        t.Fatal()
    }
}

func TestPrefixExpressions(t *testing.T) {
    input := "-5; !asdf;"
    tests := []string {
        "expression stmt:: value:(-5)",
        "expression stmt:: value:(!asdf)",
    }

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:'%s', got:'%s'", tests[i], node.ToString())
        }
    }
    if len(p.errors) > 0 {
        for _,e := range p.errors {
            println(e)
        }
        t.Fatal()
    }
}

func TestInfixExpressions(t *testing.T) {
    input := "5 + 5; 5 - 5; 5 / 5; 5 * 5; 5 < 5; 5 > 5; 5 == 5; 5 != 5;"
    tests := []string {
        "expression stmt:: value:(5 + 5)",
        "expression stmt:: value:(5 - 5)",
        "expression stmt:: value:(5 / 5)",
        "expression stmt:: value:(5 * 5)",
        "expression stmt:: value:(5 < 5)",
        "expression stmt:: value:(5 > 5)",
        "expression stmt:: value:(5 == 5)",
        "expression stmt:: value:(5 != 5)",
    }

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:'%s', got:'%s'", tests[i], node.ToString())
        }
    }
    if len(p.errors) > 0 {
        for _,e := range p.errors {
            println(e)
        }
        t.Fatal()
    }
}

func TestComplexExpression(t *testing.T) {
    input :=  `
    -a * b;
    !-a;
    a + b + c;
    a + b - c;
    a * b * c;
    a * b / c;
    a + b / c;
    a + b * c + d / e - f;
    3 + 4;
    -5 * 5;
    5 > 4 == 3 < 4;
    5 < 4 != 3 > 4;
    3 + 4 * 5 == 3 * 1 + 4 * 5;
    1 + (2 + 3) + 4;
    (5 + 5) * 2;
    2 / (5 + 5);
    -(5 + 5);
    !(true == true);`
    tests := []string {
        "expression stmt:: value:((-a) * b)",
        "expression stmt:: value:(!(-a))",
        "expression stmt:: value:((a + b) + c)",
        "expression stmt:: value:((a + b) - c)",
        "expression stmt:: value:((a * b) * c)",
        "expression stmt:: value:((a * b) / c)",
        "expression stmt:: value:(a + (b / c))",
        "expression stmt:: value:(((a + (b * c)) + (d / e)) - f)",
        "expression stmt:: value:(3 + 4)",
        "expression stmt:: value:((-5) * 5)",
        "expression stmt:: value:((5 > 4) == (3 < 4))",
        "expression stmt:: value:((5 < 4) != (3 > 4))",
        "expression stmt:: value:((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))",
        "expression stmt:: value:((1 + (2 + 3)) + 4)",
        "expression stmt:: value:((5 + 5) * 2)",
        "expression stmt:: value:(2 / (5 + 5))",
        "expression stmt:: value:(-(5 + 5))",
        "expression stmt:: value:(!(true == true))",
    }

    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:%s  got:%s", tests[i], node.ToString())
        }
    }
    if len(p.errors) > 0 {
        for _,e := range p.errors {
            println(e)
        }
        t.Fatal()
    }
}

func TestBoolLiterals(t *testing.T) {
    input := "true; false; 3 > 5 == false; 3 < 5 == true;"
    tests := []string {
        "expression stmt:: value:true",
        "expression stmt:: value:false",
        "expression stmt:: value:((3 > 5) == false)",
        "expression stmt:: value:((3 < 5) == true)",
    }
    l := lexer.New([]byte(input))
    p := New(&l)
    p.ParseTokens()

    for i,node := range p.ast {
        if node.ToString() != tests[i] {
            t.Fatalf("Expected:%s  got:%s", tests[i], node.ToString())
        }
    }
    if len(p.errors) > 0 {
        for _,e := range p.errors {
            println(e)
        }
        t.Fatal()
    }
}
