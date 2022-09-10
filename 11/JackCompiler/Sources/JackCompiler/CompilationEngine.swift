import Foundation
class CompilationEngine{
    let tokenizer:JackTokenizer
    let outputFileURL:URL
    var numIndents = 0
    var analyzingSuccessful = false
    var className:String!
    var currentFunctionType:String!
    var currentFunctionName:String!
    var symbolTable = SymbolTable()
    let vmWriter:VMWriter
    var labelNumber = 0
    init(tokenizer:JackTokenizer,outputFileURL:URL) {
        self.tokenizer = tokenizer
        self.outputFileURL = outputFileURL
        self.vmWriter = VMWriter(outputURL: outputFileURL)
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
        guard eat(token: "class") else {return false}
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        self.className = tokenizer.currentToken
        tokenizer.advance()
        guard eat(token: "{") else{return false}
        tokenizer.advance()
        while eat(token: "static") || eat(token: "field"){
            guard compileClassVarDec() else{return false}
        }
        while eat(token: "constructor") || eat(token: "function") || eat(token: "method"){
            guard compileSubroutineDec() else {return false}
        }
        guard eat(token: "}") else {return false}
        return true
    }
    func compileClassVarDec()->Bool{
        let kind:SymbolTable.Kind = tokenizer.currentToken == "static" ? .static : .field
        tokenizer.advance()
        guard eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
        let type = tokenizer.currentToken
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        symbolTable.define(name: tokenizer.currentToken, type: type, kind: kind)
        tokenizer.advance()
        while eat(token: ","){
            tokenizer.advance()
            guard eat(tokenType: "identifier") else {return false}
            symbolTable.define(name: tokenizer.currentToken, type: type, kind: kind)
            tokenizer.advance()
        }
        guard eat(token: ";") else {return false}
        tokenizer.advance()
        return true
    }
    func compileSubroutineDec()->Bool{
        symbolTable.startSubroutine()
        currentFunctionType = tokenizer.currentToken
        tokenizer.advance()
        guard eat(token: "void") ||  eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        currentFunctionName = tokenizer.currentToken
        tokenizer.advance()
        if currentFunctionType == "method"{
            symbolTable.define(name: "this", type: className, kind: .arg)
        }
        guard eat(token: "(") else {return false}
        tokenizer.advance()
        guard compileParameterList() else {return false}
        guard eat(token: ")") else {return false}
        tokenizer.advance()
        guard compileSubroutineBody() else {return false}
        return true
    }
    func compileSubroutineBody()->Bool{
        guard eat(token: "{") else {return false}
        tokenizer.advance()
        while eat(token: "var"){
            guard compileVarDec() else {return false}
        }
        vmWriter.writeFunction(name: "\(className!).\(currentFunctionName!)", nLocals: symbolTable.varCount(kind: .var))
        if currentFunctionType == "method"{
            vmWriter.writePush(segment: .arg, index: 0)
            vmWriter.writePop(segment: .pointer, index: 0)
        }
        if currentFunctionType == "constructor"{
            let numFields = symbolTable.varCount(kind: .field)
            vmWriter.writePush(segment: .const, index: numFields)
            vmWriter.writeCall(name: "Memory.alloc", nArgs: 1)
            vmWriter.writePop(segment: .pointer, index: 0)
        }
        guard compileStatements() else {return false}
        guard eat(token: "}") else {return false}
        tokenizer.advance()
        return true
    }
    func compileParameterList()->Bool{
        if eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier"){
            var type = tokenizer.currentToken
            tokenizer.advance()
            guard eat(tokenType: "identifier") else{return false}
            symbolTable.define(name: tokenizer.currentToken, type: type, kind: .arg)
            tokenizer.advance()
            while eat(token: ","){
                tokenizer.advance()
                guard eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
                type = tokenizer.currentToken
                tokenizer.advance()
                guard eat(tokenType: "identifier") else {return false}
                symbolTable.define(name: tokenizer.currentToken, type: type, kind: .arg)
                tokenizer.advance()
            }
        }
        return true
    }
    func compileVarDec()->Bool{
        tokenizer.advance()
        guard eat(token: "void") ||  eat(token: "char") || eat(token: "int") || eat(token: "boolean") || eat(tokenType: "identifier") else {return false}
        let type = tokenizer.currentToken
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        symbolTable.define(name: tokenizer.currentToken, type: type, kind: .var)
        tokenizer.advance()
        while eat(token: ","){
             tokenizer.advance()
             guard eat(tokenType: "identifier") else {return false}
            symbolTable.define(name: tokenizer.currentToken, type: type, kind: .var)
             tokenizer.advance()
        }
        guard eat(token: ";") else {return false}
        tokenizer.advance()
        return true
    }
    func compileStatements()->Bool{
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
        return true
    }
    func compileDo()->Bool{
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {
            return false
        }
        var name = tokenizer.currentToken
        tokenizer.advance()
        if eat(token: "("){
            name = "\(className!).\(name)"
            tokenizer.advance()
            vmWriter.writePush(segment: .pointer, index: 0)
            let result = compileExpressionList()
            guard result.0 else{return false}
            guard eat(token: ")") else {return false}
            tokenizer.advance()
            vmWriter.writeCall(name: name, nArgs: result.1+1)
        }else if eat(token: "."){
            tokenizer.advance()
            guard eat(tokenType: "identifier") else {return false}
            let isFunctionCall = symbolTable.typeOf(name: name) == "none"
            if isFunctionCall{
                name = name + ".\(tokenizer.currentToken)"
            }else{
                vmWriter.writePush(segment: VMWriter.Segment(rawValue: symbolTable.kindOf(name: name).rawValue)!, index: symbolTable.indexOf(name: name))
                name = "\(symbolTable.typeOf(name: name)).\(tokenizer.currentToken)"
            }
            tokenizer.advance()
            guard eat(token: "(") else {return false}
            tokenizer.advance()
            let result = compileExpressionList()
            guard result.0 else{return false}
            guard eat(token: ")") else {return false}
            tokenizer.advance()
            vmWriter.writeCall(name: name, nArgs: isFunctionCall ? result.1 : result.1 + 1)
        }
        guard eat(token: ";") else {return false}
        tokenizer.advance()
        vmWriter.writePop(segment: .temp, index: 0)
        return true
    }
    func compileLet()->Bool{
        tokenizer.advance()
        guard eat(tokenType: "identifier") else {return false}
        let identifier = tokenizer.currentToken
        var identifierIsArrayReference=false
        tokenizer.advance()
        if eat(token: "["){
            identifierIsArrayReference.toggle()
            tokenizer.advance()
            vmWriter.writePush(segment: VMWriter.Segment(rawValue: symbolTable.kindOf(name: identifier).rawValue)!, index: symbolTable.indexOf(name: identifier))
            guard compileExpression() else {return false}
            vmWriter.writeArithmetic(command: .add)
            guard eat(token: "]") else {return false}
            tokenizer.advance()
        }
        guard eat(token: "=") else {return false}
        tokenizer.advance()
        guard compileExpression() else {return false}
        guard eat(token: ";") else {return false}
        if identifierIsArrayReference{
            vmWriter.writePop(segment: .temp, index: 0)
            vmWriter.writePop(segment: .pointer, index: 1)
            vmWriter.writePush(segment: .temp, index: 0)
            vmWriter.writePop(segment: .that, index: 0)
        }else{
            vmWriter.writePop(segment: VMWriter.Segment(rawValue: symbolTable.kindOf(name: identifier).rawValue)!, index: symbolTable.indexOf(name: identifier))
        }
        tokenizer.advance()
        return true
    }
    func compileWhile()->Bool{
        tokenizer.advance()
        let labelOne = getLabel()
        let labelTwo = getLabel()
        vmWriter.writeLabel(label: labelOne)
        guard eat(token: "(") else {return false}
        tokenizer.advance()
        guard compileExpression() else {return false}
        guard eat(token: ")") else{return false}
        tokenizer.advance()
        vmWriter.writeArithmetic(command: .not)
        vmWriter.writeIf(label: labelTwo)
        guard eat(token: "{") else {return false}
        tokenizer.advance()
        guard compileStatements() else {return false}
        guard eat(token: "}") else {return false}
        vmWriter.writeGoto(label: labelOne)
        vmWriter.writeLabel(label: labelTwo)
        tokenizer.advance()
        return true

    }
    func compileReturn()->Bool{
        tokenizer.advance()
        if !eat(token: ";"){
            guard compileExpression() else {return false}
            vmWriter.writeReturn()
        }else{
            vmWriter.writePush(segment: .const, index: 0)
            vmWriter.writeReturn()
        }
        guard eat(token: ";") else {return false}
        tokenizer.advance()
        return true

    }
    func compileIf()->Bool{
        tokenizer.advance()
        guard eat(token: "(") else {return false}
        tokenizer.advance()
        guard compileExpression() else {return false}
        let labelOne = getLabel()
        vmWriter.writeArithmetic(command: .not)
        vmWriter.writeIf(label: labelOne)
        guard eat(token: ")") else {return false}
        tokenizer.advance()
        guard eat(token: "{") else {return false}
        tokenizer.advance()
        guard compileStatements() else {return false}
        guard eat(token: "}") else {return false}
        tokenizer.advance()
        if eat(token: "else"){
            let labelTwo = getLabel()
            vmWriter.writeGoto(label: labelTwo)
            vmWriter.writeLabel(label: labelOne)
            tokenizer.advance()
            guard eat(token: "{") else {return false}
            tokenizer.advance()
            guard compileStatements() else {return false}
            guard eat(token: "}") else {return false}
            tokenizer.advance()
            vmWriter.writeLabel(label: labelTwo)
        }else{
            vmWriter.writeLabel(label: labelOne)
        }
        return true
    }
    func compileExpression()->Bool{
        guard compileTerm() else {return false}
        let operators:[String:VMWriter.ArithmeticCommand] = ["+":.add,"-":.sub,"*":.mult,"/":.div,"&":.and,"|":.or,"<":.lt,">":.gt,"=":.eq]
        while operators.keys.contains(tokenizer.currentToken){
            let op = operators[tokenizer.currentToken]!
            tokenizer.advance()
            guard compileTerm() else {return false}
            vmWriter.writeArithmetic(command: op)
        }
       return true
    }
    
    func compileTerm()->Bool{
        let keywordConstants = ["true","false","null","this"]
        let unaryOperators:[String:VMWriter.ArithmeticCommand] = ["-":.neg,"~":.not]
        if eat(tokenType: "integerConstant"){
            vmWriter.writePush(segment: .const, index: tokenizer.intVal())
            tokenizer.advance()
        }else if eat(tokenType: "stringConstant"){
            let string = tokenizer.currentToken.replacingOccurrences(of: "\"", with: "")
            vmWriter.writePush(segment: .const, index: string.count)
            vmWriter.writeCall(name: "String.new", nArgs: 1)
            for character in string{
                vmWriter.writePush(segment: .const, index: Int(character.unicodeScalarCodePoint()))
                    vmWriter.writeCall(name: "String.appendChar", nArgs: 2)
            }
            tokenizer.advance()
        }else if keywordConstants.contains(tokenizer.currentToken){
            if tokenizer.currentToken == "true"{
                vmWriter.writePush(segment: .const, index: 1)
                vmWriter.writeArithmetic(command: .neg)
            }else if tokenizer.currentToken == "this"{
                vmWriter.writePush(segment: .pointer, index: 0)
            }else{
                vmWriter.writePush(segment: .const, index: 0)
            }
            tokenizer.advance()
        }else if eat(tokenType: "identifier"){
            var identifier = tokenizer.currentToken
            tokenizer.advance()
            if eat(token: "["){
                vmWriter.writePush(segment: VMWriter.Segment(rawValue: symbolTable.kindOf(name: identifier).rawValue)!, index: symbolTable.indexOf(name: identifier))
                tokenizer.advance()
                guard compileExpression() else {return false}
                vmWriter.writeArithmetic(command: .add)
                vmWriter.writePop(segment: .pointer, index: 1)
                vmWriter.writePush(segment: .that, index: 0)
                guard eat(token: "]") else {return false}
                tokenizer.advance()
            }else if eat(token: "("){
                tokenizer.advance()
                guard compileExpressionList().0 else{return false}
                guard eat(token: ")") else {return false}
                tokenizer.advance()
            }else if eat(token: "."){
                tokenizer.advance()
                guard eat(tokenType: "identifier") else {return false}
                let isMethodCall =  symbolTable.typeOf(name: identifier) != "none"
                if !isMethodCall{
                    identifier = "\(identifier).\(tokenizer.currentToken)"
                }else{
                    vmWriter.writePush(segment: VMWriter.Segment(rawValue: symbolTable.kindOf(name: identifier).rawValue)!, index: symbolTable.indexOf(name: identifier))
                    identifier = "\(symbolTable.typeOf(name: identifier)).\(tokenizer.currentToken)"
                }
                tokenizer.advance()
                guard eat(token: "(") else {return false}
                tokenizer.advance()
                let result = compileExpressionList()
                guard result.0 else{return false}
                guard eat(token: ")") else {return false}
                vmWriter.writeCall(name: identifier, nArgs: isMethodCall ?  result.1 + 1 : result.1)
                tokenizer.advance()
            }else{
                vmWriter.writePush(segment: VMWriter.Segment(rawValue: symbolTable.kindOf(name: identifier).rawValue)!, index: symbolTable.indexOf(name: identifier))
            }
        }else if eat(token: "("){
            tokenizer.advance()
            guard compileExpression() else {return false}
            guard eat(token: ")") else {return false}
            tokenizer.advance()
        }else if unaryOperators.keys.contains(tokenizer.currentToken){
            let op = tokenizer.currentToken
            tokenizer.advance()
            guard compileTerm() else {return false}
            vmWriter.writeArithmetic(command: unaryOperators[op]!)
        }else{
            return false
        }
        return true

    }
    func compileExpressionList()->(Bool,Int){
        var numArgs = 0
        guard !eat(token: ")") else {return (true,numArgs)}
        guard compileExpression() else {return (false,numArgs)}
        numArgs += 1
        while eat(token: ","){
            tokenizer.advance()
            guard compileExpression() else {return (false,numArgs)}
            numArgs += 1
        }
        return (true,numArgs)

    }
    func getLabel()->String{
        let label = "\(className!)-L\(labelNumber)"
        labelNumber += 1
        return label
    }
    
    
}


