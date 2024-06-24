package lexer

import (
	"interpreter/token"
	"testing"
)


func TestLexer(t *testing.T) {
    input := `
        let five = 5;
        let ten = 10;
        
        let add = fn(x,y) {
            x + y;
        };
        
        let result = add(five, ten);
        !-/*5; 5 < 10 > 5;
        if (5 < 10) { return true; } else { return false; }
        10 == 10; 10 != 9;
        `

    tests := []token.Token {
        // variable decliration
        { TokenType: token.Keyw_let, Literal: "let" },
        { TokenType: token.Type_identifier, Literal: "five" },
        { TokenType: token.Syn_assign, Literal: "=" },
        { TokenType: token.Type_int, Literal: "5" },
        { TokenType: token.Syn_semicolon, Literal: ";" },

        // variable decliration
        { TokenType: token.Keyw_let, Literal: "let" },
        { TokenType: token.Type_identifier, Literal: "ten" },
        { TokenType: token.Syn_assign, Literal: "=" },
        { TokenType: token.Type_int, Literal: "10" },
        { TokenType: token.Syn_semicolon, Literal: ";" },

        // function decliration
        { TokenType: token.Keyw_let, Literal: "let" },
        { TokenType: token.Type_identifier, Literal: "add" },
        { TokenType: token.Syn_assign, Literal: "=" },
        { TokenType: token.Keyw_fn, Literal: "fn" },
        { TokenType: token.Syn_lparen, Literal: "(" },
        { TokenType: token.Type_identifier, Literal: "x" },
        { TokenType: token.Syn_comma, Literal: "," },
        { TokenType: token.Type_identifier, Literal: "y" },
        { TokenType: token.Syn_rparen, Literal: ")" },
        { TokenType: token.Syn_lbrace, Literal: "{" },
        // function body
        { TokenType: token.Type_identifier, Literal: "x" },
        { TokenType: token.Op_plus, Literal: "+" },
        { TokenType: token.Type_identifier, Literal: "y" },
        { TokenType: token.Syn_semicolon, Literal: ";" },
       // end of function
        { TokenType: token.Syn_rbrace, Literal: "}" },
        { TokenType: token.Syn_semicolon, Literal: ";" },

        // variable decliration and calling function
        { TokenType: token.Keyw_let, Literal: "let" },
        { TokenType: token.Type_identifier, Literal: "result" },
        { TokenType: token.Syn_assign, Literal: "=" },
        { TokenType: token.Type_identifier, Literal: "add" },
        { TokenType: token.Syn_lparen, Literal: "(" },
        { TokenType: token.Type_identifier, Literal: "five" },
        { TokenType: token.Syn_comma, Literal: "," },
        { TokenType: token.Type_identifier, Literal: "ten" },
        { TokenType: token.Syn_rparen, Literal: ")" },
        { TokenType: token.Syn_semicolon, Literal: ";" },

        //extra ops
        { TokenType: token.Op_bang, Literal: "!" },
        { TokenType: token.Op_minus, Literal: "-" },
        { TokenType: token.Op_slash, Literal: "/" },
        { TokenType: token.Op_asterisk, Literal: "*" },
        { TokenType: token.Type_int, Literal: "5" },
        { TokenType: token.Syn_semicolon, Literal: ";" },
        { TokenType: token.Type_int, Literal: "5" },
        { TokenType: token.Op_lessthan, Literal: "<" },
        { TokenType: token.Type_int, Literal: "10" },
        { TokenType: token.Op_greaterthan, Literal: ">" },
        { TokenType: token.Type_int, Literal: "5" },
        { TokenType: token.Syn_semicolon, Literal: ";" },

        //if/else
        { TokenType: token.Keyw_if, Literal: "if" },
        { TokenType: token.Syn_lparen, Literal: "(" },
        { TokenType: token.Type_int, Literal: "5" },
        { TokenType: token.Op_lessthan, Literal: "<" },
        { TokenType: token.Type_int, Literal: "10" },
        { TokenType: token.Syn_rparen, Literal: ")" },
        { TokenType: token.Syn_lbrace, Literal: "{" },
        { TokenType: token.Keyw_return, Literal: "return" },
        { TokenType: token.Type_bool, Literal: "true" },
        { TokenType: token.Syn_semicolon, Literal: ";" },
        { TokenType: token.Syn_rbrace, Literal: "}" },
        { TokenType: token.Keyw_else, Literal: "else" },
        { TokenType: token.Syn_lbrace, Literal: "{" },
        { TokenType: token.Keyw_return, Literal: "return" },
        { TokenType: token.Type_bool, Literal: "false" },
        { TokenType: token.Syn_semicolon, Literal: ";" },
        { TokenType: token.Syn_rbrace, Literal: "}" },

        //equal/not equal
        { TokenType: token.Type_int, Literal: "10" },
        { TokenType: token.Op_equal, Literal: "==" },
        { TokenType: token.Type_int, Literal: "10" },
        { TokenType: token.Syn_semicolon, Literal: ";" },
        { TokenType: token.Type_int, Literal: "10" },
        { TokenType: token.Op_notEqual, Literal: "!=" },
        { TokenType: token.Type_int, Literal: "9" },
        { TokenType: token.Syn_semicolon, Literal: ";" },

        // eof
        { TokenType: token.Eof, Literal: "" },
    };

    lex := New([]byte(input))
    for _,test := range tests {
        tok := lex.NextToken()
        if test.Literal != tok.Literal {
            t.Fatalf("Expected Literal:%s got:%s\n", test.Literal, tok.Literal)
        }
        if test.TokenType != tok.TokenType {
            t.Fatalf("Expected type:%d got:%d\n", test.TokenType, tok.TokenType)
        }
    }
}
