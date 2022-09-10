import Cocoa


extension String{
    func removeWhitespace() -> String{
        return self.replacingOccurrences(of: " ", with: "")
    }
}
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
            print("called")
            try write(to: url)
        }
    }
}



class Parser{
    var filePointer:UnsafeMutablePointer<FILE>
    var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
    var lineCap: Int = 0
    var currentCommand=""
    var commandNumber = -1
    var bytesRead:Int
    
    func reset(with fileUrl:URL){
        self.currentCommand = ""
        self.commandNumber = -1
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return
        }
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(fileUrl.path,"r") else {
            return
        }
        self.filePointer = filePointer
        self.bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        
    }
    init?(fileUrl:URL) {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return nil
        }
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(fileUrl.path,"r") else {
            return nil
        }
        self.filePointer = filePointer
        self.bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
    }
    func advance(){
        while hasMoreCommands(){
            let lineAsString = String.init(cString:lineByteArrayPointer!).removeWhitespace().trimmingCharacters(in: .newlines)
            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
            if !lineAsString.isEmpty && lineAsString.first != "/"{
                if let index = lineAsString.firstIndex(of: "/"){
                    let indexOne = lineAsString.startIndex
                    let indexTwo = lineAsString.index(before: index)
                    self.currentCommand = String(lineAsString[indexOne...indexTwo])
                }else{
                    self.currentCommand = lineAsString
                }
                if commandType() != "L"{
                    commandNumber += 1
                }
                break
            }
           
        }
            
    }
    func commandType()->String{
        if currentCommand.first == "@"{
            return "A"
        }else if currentCommand.first == "("{
            return "L"
        }else{
            return "C"
        }
    }
    
    func symbol()->String{
        let indexOne = currentCommand.index(after: currentCommand.startIndex)
        let indexTwo:String.Index
        if currentCommand.contains("("){
            indexTwo = currentCommand.index(before: currentCommand.index(before: currentCommand.endIndex))
        }else{
            indexTwo = currentCommand.index(before: currentCommand.endIndex)
        }
        return String(currentCommand[indexOne...indexTwo])
    }
    
    func dest()->String{
        if let indexOfEq = currentCommand.firstIndex(of: "="){
            let indexOne = currentCommand.startIndex
            let indexTwo = currentCommand.index(before: indexOfEq)
            return String(currentCommand[indexOne...indexTwo])
        }
        return "null"
    }
    
    func comp() -> String{
        let indexOfEq = currentCommand.firstIndex(of: "=")
        let indexOfSemi = currentCommand.firstIndex(of: ";")
        let indexOne:String.Index
        let indexTwo:String.Index
        if let equalIndex = indexOfEq, let semiIndex = indexOfSemi{
            indexOne = currentCommand.index(after: equalIndex)
            indexTwo = currentCommand.index(before: semiIndex)
        }else if let equalIndex = indexOfEq{
            indexOne = currentCommand.index(after: equalIndex)
            indexTwo = currentCommand.index(before: currentCommand.endIndex)
        }else{
            indexOne = currentCommand.startIndex
            indexTwo = currentCommand.index(before: indexOfSemi!)
        }
        return String(currentCommand[indexOne...indexTwo])
    }
    
    func jump()->String{
        var jump = "null"
        if let indexOfSemi = currentCommand.firstIndex(of: ";"){
            let indexOne = currentCommand.index(after: indexOfSemi)
            let indexTwo = currentCommand.index(before: currentCommand.endIndex)
            jump = String(currentCommand[indexOne...indexTwo])
        }
        return jump
    }
    
    func hasMoreCommands()->Bool{
        if bytesRead > 0{
            return true
        }
        fclose(filePointer)
        return false
    }

}


class Code{
    let dest:[String:String]=[
        "null":"000",
        "M":"001",
        "D":"010",
        "MD":"011",
        "A":"100",
        "AM":"101",
        "AD":"110",
        "AMD":"111"
    ]
    let jump:[String:String]=[
        "null":"000",
        "JGT":"001",
        "JEQ":"010",
        "JGE":"011",
        "JLT":"100",
        "JNE":"101",
        "JLE":"110",
        "JMP":"111"
    ]
    let comp:[String:String]=[
        "0":"0101010",
        "1":"0111111",
        "-1":"0111010",
        "D":"0001100",
        "A":"0110000",
        "!D":"0001101",
        "!A":"0110001",
        "-D":"0001111",
        "-A":"0110011",
        "D+1":"0011111",
        "A+1":"0110111",
        "D-1":"0001110",
        "A-1":"0110010",
        "D+A":"0000010",
        "D-A":"0010011",
        "A-D":"0000111",
        "D&A":"0000000",
        "D|A":"0010101",
        "M":"1110000",
        "!M":"1110001",
        "-M":"1110011",
        "M+1":"1110111",
        "M-1":"1110010",
        "D+M":"1000010",
        "D-M":"1010011",
        "M-D":"1000111",
        "D&M":"1000000",
        "D|M":"1010101"
    ]
    
    func dest(for destination:String)->String{
        return dest[destination]!
    }
    func comp(for computation:String)->String{
        return comp[computation]!
    }
    func jump(for condition:String)->String{
        return jump[condition]!
    }
    func binary(for integer:Int)->String{
        var binary = String(integer,radix: 2)
        var numOfPaddingZeros = 16 - binary.count
        for i in 0..<numOfPaddingZeros{
            binary = "0" + binary
        }
        return binary
    }

    
}



let home = FileManager.default.homeDirectoryForCurrentUser
let fileUrl = home
.appendingPathComponent("Documents")
.appendingPathComponent("Rect")
.appendingPathExtension("asm")
let outputFileUrl = home
.appendingPathComponent("Documents")
.appendingPathComponent("Rect")
.appendingPathExtension("hack")

var parser = Parser(fileUrl: fileUrl)!
var codeGenerator = Code()
var symbolTable = ["SP":0, "LCL":1,"ARG":2,"THIS":3,"THAT":4,"R0":0,"R1":1,"R2":2,"R3":3,"R4":4,"R5":5,"R6":6,"R7":7,"R8":8,"R9":9,"R10":10,"R11":11,"R12":12,"R13":13,"R14":14,"R15":15,"SCREEN":16384,"KBD":24576]
var nextAvailableMemoryLocation = 16
var output = ""

//First Pass
while parser.hasMoreCommands(){
    parser.advance()
    if parser.commandType() == "L"{
        symbolTable[parser.symbol()] = parser.commandNumber + 1
    }
}
parser.reset(with: fileUrl)
//Second Pass
while parser.hasMoreCommands(){
    parser.advance()
    if parser.commandType() == "A"{
        let symbol = parser.symbol()
        if let int = Int(symbol){
            output = codeGenerator.binary(for: int)
        }else if let address = symbolTable[symbol]{
            output = codeGenerator.binary(for: address)
        }else{
            symbolTable[symbol] = nextAvailableMemoryLocation
            output = codeGenerator.binary(for: nextAvailableMemoryLocation)
            nextAvailableMemoryLocation += 1
        }

    }else if parser.commandType() == "C"{
        let comp = codeGenerator.comp(for: parser.comp())
        let dest = codeGenerator.dest(for: parser.dest())
        let jump = codeGenerator.jump(for: parser.jump())
        output = "111"+comp+dest+jump
    }else{
        continue
    }
   try? output.appendLine(to: outputFileUrl)
}



