import Cocoa
import Foundation
extension String {
    func appendLine(to url: URL) throws {
        try self.appending("\n").append(to: url)
    }
    func append(to url: URL) throws {
        let data = self.data(using: String.Encoding.utf8)
        try data?.append(to: url)
    }
}

extension Data {
    func append(to url: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: url)
        }
    }
}
class JackTokenizer{
    let keywords = ["class","constructor","function","method","field","static","var","int","char","boolean","void","true","false","null","this","let","do","if","else","while","return"]
    let symbols = ["{","}","(",")","[","]",".",",",";","+","-","*","/","&","|","<",">","=","~"]
    let XMLConversions = ["<":"&lt;",">":"&gt;","\"":"&quot;","&":"&amp;"]
    var tokens = [String]()
    var currentTokenIndex = -1
    var currentToken = ""
    var isOptimalForXML = false
    func advance(){
        currentTokenIndex += 1
        currentToken = tokens[currentTokenIndex]
    }
    func hasMoreTokens()->Bool{
        return  currentTokenIndex + 1 < tokens.count
    }
    func tokenType()->String{
        if let _ = Int(currentToken){
            return "integerConstant"
        }else if currentToken.contains("\""){
            return "stringConstant"
        }else if isKeyword(token: currentToken){
            return "keyword"
        }else if isSymbol(token: currentToken){
            return "symbol"
        }else{
            return "identifier"
        }
    }
    
    func keyword()->String{
        return currentToken
    }
    
    func symbol()->String{
        if !isOptimalForXML{
            return currentToken
        }else{
            if let conversion = XMLConversions[currentToken]{
                return conversion
            }
            return currentToken
        }
    }
    func identifier()->String{
        return currentToken
    }
    func intVal()->Int{
        return Int(currentToken)!
    }
    func stringVal()->String{
        return currentToken.replacingOccurrences(of: "\"", with: "")
    }
    
    func isKeyword(token:String)->Bool{
        return keywords.contains(token)
    }
    func isSymbol(token:String)->Bool{
        return symbols.contains(token)
    }
    func extractTokensFromLine(line:String){
        var partialToken = ""
        var inQuote = false
        for character in line{
            if character == "\""{
                inQuote.toggle()
               // continue
            }
            if character.isWhitespace && !inQuote{
                if !partialToken.isEmpty{
                    tokens.append(partialToken)
                    partialToken = ""
                }
                continue
            }
            if isSymbol(token: String(character)) && !inQuote{
                if !partialToken.isEmpty{
                    tokens.append(partialToken)
                    partialToken = ""
                }
                tokens.append(String(character))
                continue
            }
            partialToken = partialToken + String(character)
        }
    }
    
    init?(inputFileURL:URL) {
       guard let contents = try? String(contentsOf: inputFileURL) else{
            return nil
        }
        var insideBlockComment = false
        contents.enumerateLines { (line, _) in
              var lineCopy = line.trimmingCharacters(in: .whitespacesAndNewlines)
              //If line is empty, discard the line
              guard lineCopy.count != 0 else {
                  return
              }
              //if line contains both /** and */, discard it as it is a comment
              guard !(lineCopy.contains("/**") && lineCopy.contains("*/")) else {return}
              guard !(lineCopy.contains("/**") || lineCopy.contains("*/")) else {insideBlockComment.toggle();return}
              //If the first character of the line is /, discard it as it is a comment
              guard !(lineCopy.first! == "/") else{
                return
              }
              guard !insideBlockComment else {return}
              if lineCopy.contains("//"){
                lineCopy = String(lineCopy[lineCopy.startIndex...lineCopy.index(before: lineCopy.index(before: lineCopy.lastIndex(of: "/")!))])
              }
              self.extractTokensFromLine(line: lineCopy)
        }
    }
}


