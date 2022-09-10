import Foundation
class CompilationEngine{
    let tokenizer:JackTokenizer
    let outputFileURL:URL
    var numIndents = 0
    var analyzingSuccessful = false
    init(tokenizer:JackTokenizer,outputFileURL:URL) {
        self.tokenizer = tokenizer
        self.outputFileURL = outputFileURL
        try? "".write(to: outputFileURL, atomically: true, encoding: .utf8)
        tokenizer.advance()
        self.analyzingSuccessful = compileClass()
    }
    func eat(token:String)->Bool{
        return tokenizer.currentToken == token
    }
    func eat(tokenType:String)->Bool{
        return tokenizer.tokenType() == tokenType
    }
    //outputs either the program structure description or the token
    func output(_ arg1:String,_ arg2:String? = nil){
        if let arg2 = arg2{
            try? (String(repeating: " ", count: numIndents) + "<\(arg2)>\(arg1)</\(arg2)>").appendLine(to: outputFileURL)
        }else{
            try? (String(repeating: " ", count: numIndents)+arg1).appendLine(to: outputFileURL)
        }
    }
    
    func compileClass()->Bool{
        numIndents = 0
        guard eat(token: "class") else {return false}
        output("<class>")
        numIndents += 1
        output("class", "keyword")
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, "identifier")
        tokenizer.advance()
        guard eat(token: "{") else{return false}
        output("{", "symbol")
        tokenizer.advance()
        while eat(token: "static") || eat(token: "field"){
            guard compileClassVarDec() else{return false}
        }
        while eat(token: "constructor") || eat(token: "function") || eat(token: "method"){
            guard compileSubroutineDec() else {return false}
        }
        guard eat(token: "}") else {return false}
        output("}", "symbol")
        numIndents -= 1
        output("</class>")
        return true
    }
    func compileClassVarDec()->Bool{
        output("<classVarDec>")
        numIndents += 1
        output(tokenizer.currentToken, "keyword")
        tokenizer.advance()
        guard eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, tokenizer.tokenType())
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, "identifier")
        tokenizer.advance()
        while eat(token: ","){
            output(",", "symbol")
            tokenizer.advance()
            guard eat(tokenType: "identifier") else {return false}
            output(tokenizer.currentToken, "identifier")
            tokenizer.advance()
        }
        guard eat(token: ";") else {return false}
        output(";", "symbol")
        tokenizer.advance()
        numIndents -= 1
        output("</classVarDec>")
        return true
    }
    func compileSubroutineDec()->Bool{
        output("<subroutineDec>")
        numIndents += 1
        output(tokenizer.currentToken, "keyword")
        tokenizer.advance()
        guard eat(token: "void") ||  eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, tokenizer.tokenType())
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, "identifier")
        tokenizer.advance()
        guard eat(token: "(") else {return false}
        output("(", "symbol")
        tokenizer.advance()
        guard compileParameterList() else {return false}
        guard eat(token: ")") else {return false}
        output(")", "symbol")
        tokenizer.advance()
        guard compileSubroutineBody() else {return false}
        numIndents -= 1
        output("</subroutineDec>")
        return true
    }
    func compileSubroutineBody()->Bool{
        output("<subroutineBody>")
        numIndents += 1
        guard eat(token: "{") else {return false}
        output("{", "symbol")
        tokenizer.advance()
        while eat(token: "var"){
            guard compileVarDec() else {return false}
        }
        guard compileStatements() else {return false}
        guard eat(token: "}") else {return false}
        output("}", "symbol")
        tokenizer.advance()
        numIndents -= 1
        output("</subroutineBody>")
        return true
    }
    func compileParameterList()->Bool{
        output("<parameterList>")
        numIndents += 1
        if eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier"){
            output(tokenizer.currentToken, tokenizer.tokenType())
            tokenizer.advance()
            guard eat(tokenType: "identifier") else{return false}
            output(tokenizer.currentToken, "identifier")
            tokenizer.advance()
            while eat(token: ","){
                output(",", "symbol")
                tokenizer.advance()
                guard eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
                output(tokenizer.currentToken, tokenizer.tokenType())
                tokenizer.advance()
                guard eat(tokenType: "identifier") else {return false}
                output(tokenizer.currentToken, "identifier")
                tokenizer.advance()
            }
        }
        numIndents -= 1
        output("</parameterList>")
        return true
    }
    func compileVarDec()->Bool{
        output("<varDec>")
        numIndents += 1
        output("var", "keyword")
        tokenizer.advance()
        guard eat(token: "void") ||  eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, tokenizer.tokenType())
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, "identifier")
        tokenizer.advance()
        while eat(token: ","){
             output(",", "symbol")
             tokenizer.advance()
             guard eat(tokenType: "identifier") else {return false}
             output(tokenizer.currentToken, "identifier")
             tokenizer.advance()
        }
        guard eat(token: ";") else {return false}
        output(";", "symbol")
        tokenizer.advance()
        numIndents -= 1
        output("</varDec>")
        return true
    }
    func compileStatements()->Bool{
        output("<statements>")
        numIndents += 1
        while true{
            if eat(token: "let"){
                   guard compileLet() else {return false}
               }else if eat(token: "if"){
                   guard compileIf() else {return false}
               }else if eat(token: "while"){
                   guard compileWhile() else {return false}
               }else if eat(token: "return"){
                   guard compileReturn() else {return false}
               }else if eat(token: "do"){
                   guard compileDo() else {return false}
            }else{
                break
            }
        }
        numIndents -= 1
        output("</statements>")
        return true
    }
    func compileDo()->Bool{
        output("<doStatement>");
        numIndents += 1
        output("do", "keyword");
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {
            return false
        }
        output(tokenizer.currentToken, "identifier")
        tokenizer.advance()
        if eat(token: "("){
            output("(", "symbol")
            tokenizer.advance()
            guard compileExpressionList() else{return false}
            guard eat(token: ")") else {return false}
            output(")", "symbol");
            tokenizer.advance()
        }else if eat(token: "."){
            output(".", "symbol")
            tokenizer.advance()
            guard eat(tokenType: "identifier") else {return false}
            output(tokenizer.currentToken, "identifier")
            tokenizer.advance()
            guard eat(token: "(") else {return false}
            output("(", "symbol")
            tokenizer.advance()
            guard compileExpressionList() else{return false}
            guard eat(token: ")") else {return false}
            output(")", "symbol");
            tokenizer.advance()
        }
        guard eat(token: ";") else {return false}
        output(";", "symbol")
        tokenizer.advance()
        numIndents -= 1
        output("</doStatement>")
        return true
    }
    func compileLet()->Bool{
        output("<letStatement>")
        numIndents += 1
        output("let", "keyword")
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        output(tokenizer.currentToken, "identifier")
        tokenizer.advance()
        if eat(token: "["){
            output("[", "symbol")
            tokenizer.advance()
            guard compileExpression() else {return false}
            guard eat(token: "]") else {return false}
            output("]", "symbol")
            tokenizer.advance()
        }
        guard eat(token: "=") else {return false}
        output("=", "symbol")
        tokenizer.advance()
        guard compileExpression() else {return false}
        guard eat(token: ";") else {return false}
        output(";", "symbol")
        tokenizer.advance()
        numIndents -= 1
        output("</letStatement>")
        return true
    }
    func compileWhile()->Bool{
        output("<whileStatement>")
        numIndents += 1
        output("while", "keyword")
        tokenizer.advance()
        guard eat(token: "(") else {return false}
        output("(", "symbol")
        tokenizer.advance()
        guard compileExpression() else {return false}
        guard eat(token: ")") else{return false}
        output(")", "symbol")
        tokenizer.advance()
        guard eat(token: "{") else {return false}
        output("{", "symbol")
        tokenizer.advance()
        guard compileStatements() else {return false}
        guard eat(token: "}") else {return false}
        output("}", "symbol")
        tokenizer.advance()
        numIndents -= 1
        output("</whileStatement>")
        return true

    }
    func compileReturn()->Bool{
        output("<returnStatement>");
        numIndents += 1
        output("return", "keyword")
        tokenizer.advance()
        if !eat(token: ";"){
            guard compileExpression() else {return false}
        }
        guard eat(token: ";") else {return false}
        output(";", "symbol")
        tokenizer.advance()
        numIndents -= 1
        output("</returnStatement>");
        return true

    }
    func compileIf()->Bool{
        output("<ifStatement>")
        numIndents += 1
        output("if", "keyword")
        tokenizer.advance()
        guard eat(token: "(") else {return false}
        output("(", "symbol")
        tokenizer.advance()
        guard compileExpression() else {return false}
        guard eat(token: ")") else {return false}
        output(")", "symbol")
        tokenizer.advance()
        guard eat(token: "{") else {return false}
        output("{", "symbol")
        tokenizer.advance()
        guard compileStatements() else {return false}
        guard eat(token: "}") else {return false}
        output("}", "symbol")
        tokenizer.advance()
        if eat(token: "else"){
            output("else", "keyword")
            tokenizer.advance()
            guard eat(token: "{") else {return false}
            output("{", "symbol")
            tokenizer.advance()
            guard compileStatements() else {return false}
            guard eat(token: "}") else {return false}
            output("}", "symbol")
            tokenizer.advance()
        }
        numIndents -= 1
        output("</ifStatement>")
        return true
    }
    func compileExpression()->Bool{
        output("<expression>")
        numIndents += 1
        guard compileTerm() else {return false}
        let operators = ["+","-","*","/","&","|","<",">","="]
        while operators.contains(tokenizer.currentToken){
            output(tokenizer.symbol(), "symbol")
            tokenizer.advance()
            guard compileTerm() else {return false}
        }
       numIndents -= 1
       output("</expression>")
       return true
    }
    
    func compileTerm()->Bool{
        output("<term>")
        numIndents += 1
        let keywordConstants = ["true","false","null","this"]
        if eat(tokenType: "integerConstant"){
            output(tokenizer.currentToken, "integerConstant")
            tokenizer.advance()
        }else if eat(tokenType: "stringConstant"){
            output(tokenizer.stringVal(), "stringConstant")
            tokenizer.advance()
        }else if keywordConstants.contains(tokenizer.currentToken){
            output(tokenizer.currentToken, "keyword")
            tokenizer.advance()
        }else if eat(tokenType: "identifier"){
            output(tokenizer.currentToken, "identifier")
            tokenizer.advance()
            if eat(token: "["){
                output("[", "symbol")
                tokenizer.advance()
                guard compileExpression() else {return false}
                guard eat(token: "]") else {return false}
                output("]", "symbol")
                tokenizer.advance()
            }else if eat(token: "("){
                output("(", "symbol")
                tokenizer.advance()
                guard compileExpressionList() else{return false}
                guard eat(token: ")") else {return false}
                output(")", "symbol");
                tokenizer.advance()
            }else if eat(token: "."){
                output(".", "symbol")
                tokenizer.advance()
                guard eat(tokenType: "identifier") else {return false}
                output(tokenizer.currentToken, "identifier")
                tokenizer.advance()
                guard eat(token: "(") else {return false}
                output("(", "symbol")
                tokenizer.advance()
                guard compileExpressionList() else{return false}
                guard eat(token: ")") else {return false}
                output(")", "symbol");
                tokenizer.advance()
            }
        }else if eat(token: "("){
            output("(", "symbol")
            tokenizer.advance()
            guard compileExpression() else {return false}
            guard eat(token: ")") else {return false}
            output(")", "symbol")
            tokenizer.advance()
        }else if eat(token: "-") || eat(token: "~"){
            output(tokenizer.currentToken, "symbol")
            tokenizer.advance()
            guard compileTerm() else {return false}
        }else{
            return false
        }
        numIndents -= 1
        output("</term>")
        return true

    }
    func compileExpressionList()->Bool{
        output("<expressionList>")
        numIndents += 1
        guard !eat(token: ")") else {numIndents -= 1;output("</expressionList>");return true}
        guard compileExpression() else {return false}
        while eat(token: ","){
            output(",", "symbol")
            tokenizer.advance()
            guard compileExpression() else {return false}
        }
        numIndents -= 1
        output("</expressionList>")
        return true

    }
}


