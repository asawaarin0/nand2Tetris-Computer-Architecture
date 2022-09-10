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
class Parser{
    var commands=[String]()
    var currentCommand:String = ""
    var currentCommandIndex = -1
    var fileName=""
    var currentFunctionName=""
    var callNumber = 0
    init?(fileURL:URL){
        guard let contents = try? String(contentsOf: fileURL) else{
            return nil
        }
        contents.enumerateLines(invoking: { (line, _) in
            //If line is empty, discard the line
            guard line.count != 0 else {
                return
            }
            //If the first character of the line is a forward slash, discard the line as it is a comment
            guard line.first! != "/" else{
                return
            }
            //If the line contains "//" then extract the command from the line and discard the rest
            if line.contains("//"){
                let command = String(line[line.startIndex...line.index(before: line.firstIndex(of: "/")!)]).trimmingCharacters(in: .whitespacesAndNewlines)
                self.commands.append(command)
            }else{
                self.commands.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
    })
        let urlString = fileURL.absoluteString
        self.fileName = String(urlString[urlString.index(after: urlString.lastIndex(of: "/")!)...urlString.index(urlString.endIndex, offsetBy: -4)])
    }
    
    func hasMoreCommands()->Bool{
        if currentCommandIndex + 1  < commands.count{
            return true
        }
        return false
    }
    func advance(){
        currentCommandIndex += 1
        self.currentCommand = commands[currentCommandIndex]
    }
    func commandType()->String{
        if currentCommand.contains("push"){
            return "push"
        }
        else if currentCommand.contains("pop"){
            return "pop"
        }else if currentCommand.contains("label"){
            return "label"
        }else if currentCommand.contains("if"){
            return "if"
        }else if currentCommand.contains("goto"){
            return "goto"
        }else if currentCommand.contains("function"){
            callNumber = 0
            self.currentFunctionName = String(currentCommand[currentCommand.index(after: currentCommand.firstIndex(of: " ")!)...currentCommand.index(before: currentCommand.lastIndex(of: " ")!)])
            return "function"
        } else if currentCommand.contains("call"){
            callNumber += 1
            return "call"
        }else if currentCommand.contains("return"){
            return "return"
        }
        else{
            return "Arithmetic"
        }
    }
    
    func arg1()->String{
        let indexOne = currentCommand.firstIndex(of: " ")!
        let indexTwo = currentCommand.lastIndex(of: " ")!
        if indexOne == indexTwo{
            return String(currentCommand[currentCommand.index(after: indexOne)...currentCommand.index(before: currentCommand.endIndex)])
        }else{
            return String(currentCommand[currentCommand.index(after: indexOne)...currentCommand.index(before: indexTwo)])
        }
    }
    
    func arg2()->Int{
        let index1 = currentCommand.index(after: currentCommand.lastIndex(of: " ")!)
        let index2 = currentCommand.index(before: currentCommand.endIndex)
        return Int(String(currentCommand[index1...index2]))!
    }
}


class CodeWriter{
    var fileURL:URL
    var inputFileURL:URL
    var labelNumber=0
    init(fileURL:URL,inputFileURL:URL) {
        self.fileURL = fileURL
        self.inputFileURL = inputFileURL
    }
    func codeForIncrementingSP()->String{
        return "@SP\nM=M+1"
    }
    func codeForDecrementingSP()->String{
        return "@SP\nM=M-1"
    }
    
    func compFieldForArithmeticCommand(withName command:String)->String{
        switch command {
        case "add":
            return "D+M"
        case "sub":
            return "M-D"
        case "or":
            return "D|M"
        case "and":
            return "D&M"
        case "neg":
            return "-M"
        case "not":
            return "!M"
        default:
            return "M-D"
        }
    }
    
    func basicArithmeticTempelateCode()->String{
        return codeForDecrementingSP() + "\nA=M"
    }
    func jumpFieldForArithmeticBoolCommand(withName command:String)->String{
        switch command {
        case "eq":
            return "JEQ"
        case "lt":
            return "JLT"
        default:
            return "JGT"
        }
    }
    
    func codeForSingleOperandArithmeticCommand(withName command:String)->String{
        return "M=\(compFieldForArithmeticCommand(withName: command))\n\(codeForIncrementingSP())"
    }
    func codeForDoubleOperandArithmeticCommand(withName command:String)->String{
        return "D=M\n\(codeForDecrementingSP())\nA=M\nM=\(compFieldForArithmeticCommand(withName: command))\n\(codeForIncrementingSP())"
    }
    func codeForDoubleOperandBoolArithmeticCommand(withName command:String)->String{
        defer {
            self.labelNumber += 1
        }
        return "D=M\n\(codeForDecrementingSP())\nA=M\nD=\(compFieldForArithmeticCommand(withName: command))\n@TRUE\(labelNumber)\nD;\(jumpFieldForArithmeticBoolCommand(withName: command))\n@SP\nA=M\nM=0\n@EXIT\(labelNumber)\n0;JMP\n(TRUE\(labelNumber))\n@SP\nA=M\nM=-1\n(EXIT\(labelNumber))\n\(codeForIncrementingSP())"
    }
    
    func arithmeticCommandType(for command:String)->String{
        if command == "not" || command == "neg"{
            return "single"
        }else if command == "lt" || command == "gt" || command == "eq"{
            return "doubleBool"
        }else{
            return "double"
        }
    }
    
    func writeArithmetic(command:String){
        try? basicArithmeticTempelateCode().appendLine(to: fileURL)
        let commandType = arithmeticCommandType(for: command)
        if commandType == "single"{
            try? codeForSingleOperandArithmeticCommand(withName: command).appendLine(to: fileURL)
        }else if commandType == "double"{
            try? codeForDoubleOperandArithmeticCommand(withName: command).appendLine(to: fileURL)
        }else{
            try? codeForDoubleOperandBoolArithmeticCommand(withName: command).appendLine(to: fileURL)
        }
    }
    
    func segmentType(segment:String)->Int{
        switch segment {
        case "constant":
            return 0
        case "pointer", "temp":
            return 1
        case "static":
            return 2
        default:
            return 3
        }
    }
    func segmentPointerFor(segment:String)->String{
        switch segment {
        case "local":
            return "LCL"
        case "argument":
            return "ARG"
        case "this":
            return "THIS"
        case "that":
            return "THAT"
        default:
            return ""
        }
    }
    func codeForSegment3Type(command:String, segment:String, index:Int)->String{
        if command == "push"{
            return "@\(segmentPointerFor(segment: segment))\nD=M\n@\(index)\nD=D+A\nA=D\nD=M\n@SP\nA=M\nM=D\n\(codeForIncrementingSP())"
        }else{
            return "@\(segmentPointerFor(segment: segment))\nD=M\n@\(index)\nD=D+A\n@R13\nM=D\n\(codeForDecrementingSP())\nA=M\nD=M\n@R13\nA=M\nM=D"
        }
    }
    func codeForSegment1Type(command:String, segment:String, index:Int)->String{
        if command == "push"{
            return "@\(segment == "pointer" ? "3":"5")\nD=A\n@\(index)\nD=D+A\nA=D\nD=M\n@SP\nA=M\nM=D\n\(codeForIncrementingSP())"
        }else{
            return "@\(segment == "pointer" ? "3":"5")\nD=A\n@\(index)\nD=D+A\n@R13\nM=D\n\(codeForDecrementingSP())\nA=M\nD=M\n@R13\nA=M\nM=D"
        }
    }
    func codeForSegment2Type(command:String, segment:String, index:Int, inputFileURL:URL)->String{
        let fileName = inputFileURL.pathComponents.last!
        let endIndex = fileName.index(before: fileName.firstIndex(of: ".")!)
        let symbol = fileName[fileName.startIndex...endIndex] + ".\(index)"

        if command == "push"{
            return "@\(symbol)\nD=M\n@SP\nA=M\nM=D\n\(codeForIncrementingSP())"
        }else{
          return "\(codeForDecrementingSP())\nA=M\nD=M\n@\(symbol)\nM=D"
        }
    }
    
    
    func writePushPop(command:String, segment:String, index:Int){
        let typeOfSegment = segmentType(segment: segment)
        if typeOfSegment == 0{
            try? "@\(index)".appendLine(to: fileURL)
            try? "D=A".appendLine(to: fileURL)
            try? "@SP".appendLine(to: fileURL)
            try? "A=M".appendLine(to: fileURL)
            try? "M=D".appendLine(to: fileURL)
            try? "@SP".appendLine(to: fileURL)
            try? "M=M+1".appendLine(to: fileURL)
        }else if typeOfSegment == 3{
            try? codeForSegment3Type(command: command, segment: segment, index: index).appendLine(to: fileURL)
        }else if typeOfSegment == 1{
            try? codeForSegment1Type(command: command, segment: segment, index: index).appendLine(to: fileURL)
        }else{
            try? codeForSegment2Type(command: command, segment: segment, index: index, inputFileURL: inputFileURL).appendLine(to: fileURL)
        }
    }
    
     func writeInit(){
        //write code to set the stack pointer to 256
        try? "@256\nD=A\n@SP\nM=D".appendLine(to: fileURL)
        //write code to call sys.init
        writeCall(functionName: "Sys.init", numArgs: 0, currentFunctionName: "init", callNumber: 1)
    }
    
    func writeReturn(){
        //write code to create an endFrame variable and store the callee's LCL inside it
        try? "@LCL\nD=M\n@endFrame\nM=D".appendLine(to: fileURL)
        //write code to store the saved return address in a temporary variable retAddr
        try? "@endFrame\nD=M\n@5\nD=D-A\nA=D\nD=M\n@retAddr\nM=D".appendLine(to: fileURL)
        //write code to reposition the return value for the caller
        try? "@SP\nM=M-1\nA=M\nD=M\n@ARG\nA=M\nM=D".appendLine(to: fileURL)
        //write code to reposition SP of the caller
        try? "@ARG\nD=M+1\n@SP\nM=D".appendLine(to: fileURL)
        //write code to restore memory segments(LCL,ARG,THIS,THAT) of  collar
            // write code to restore THAT segment
        try? "@endFrame\nD=M-1\nA=D\nD=M\n@THAT\nM=D".appendLine(to: fileURL)
            // write code to restore THIS segment
        try? "@2\nD=A\n@endFrame\nD=M-D\nA=D\nD=M\n@THIS\nM=D".appendLine(to: fileURL)
            //write code to restore ARG segment
        try? "@3\nD=A\n@endFrame\nD=M-D\nA=D\nD=M\n@ARG\nM=D".appendLine(to: fileURL)
            //write code to restore LCL segment
        try? "@4\nD=A\n@endFrame\nD=M-D\nA=D\nD=M\n@LCL\nM=D".appendLine(to: fileURL)
        //write goto to jump to return address
        try? "@retAddr\nA=M\n0;JMP".appendLine(to: fileURL)

    }
    
    func codeForSavingCallerMemorySegment(segmentPointer:String)->String{
        return "@\(segmentPointer)\nD=M\n@SP\nA=M\nM=D\n\(codeForIncrementingSP())"
    }
    
    func writeCall(functionName:String,numArgs:Int,currentFunctionName:String,callNumber:Int){
        //write code for pushing return address
        try? "@\(currentFunctionName)$ret.\(callNumber)\nD=A\n@SP\nA=M\nM=D\n\(codeForIncrementingSP())".appendLine(to: fileURL)
        //write code for saving caller's memory segments
        try? codeForSavingCallerMemorySegment(segmentPointer: "LCL").appendLine(to: fileURL)
        try? codeForSavingCallerMemorySegment(segmentPointer: "ARG").appendLine(to: fileURL)
        try? codeForSavingCallerMemorySegment(segmentPointer: "THIS").appendLine(to: fileURL)
        try? codeForSavingCallerMemorySegment(segmentPointer: "THAT").appendLine(to: fileURL)
        //write code to set callee's argument segment
        try? "@5\nD=A\n@SP\nD=M-D\n@\(numArgs)\nD=D-A\n@ARG\nM=D".appendLine(to: fileURL)
        //write code to set callee's local segment
        try? "@SP\nD=M\n@LCL\nM=D".appendLine(to: fileURL)
        //write code to transfer control to the called function
        writeGoto(label: functionName)
        //write code to add return address label
        writeLabel(label: "\(currentFunctionName)$ret.\(callNumber)")
    }
    
    func writeFunction(functionName:String,numLocals:Int){
        try? "(\(functionName))".appendLine(to: fileURL)
        for _ in 0..<numLocals{
            writePushPop(command: "push", segment: "constant", index: 0)
        }
    }
    
    func writeLabel(label:String){
        try? "(\(label))".appendLine(to: fileURL)
    }
    func writeGoto(label:String){
        try? "@\(label)\n0;JMP".appendLine(to: fileURL)
    }
    func writeIf(label:String){
        try? "\(codeForDecrementingSP())\nA=M\nD=M\n@\(label)\nD;JLT\nD;JGT".appendLine(to: fileURL)
    }
  
    
}
let directoryPath = "/Users/arinasawa/Desktop/nand2tetris/projects/08/FunctionCalls/StaticsTest"
let fileURLs = try! FileManager.default.contentsOfDirectory(atPath: directoryPath)
var vmFiles = [String]()
for fileURL in fileURLs{
    let fileExtension = String(fileURL[fileURL.index(after: fileURL.lastIndex(of: ".")!)...fileURL.index(before: fileURL.endIndex)])
    if fileExtension == "vm"{
        vmFiles.append(fileURL)
    }
}
if vmFiles.isEmpty{
    print("Sorry, the directory you specified has no VM files")
}else{
    let directoryName = directoryPath[directoryPath.index(after: directoryPath.lastIndex(of: "/")!)...directoryPath.index(before: directoryPath.endIndex)]
    let outputFileURL = URL(string: "file://"+directoryPath + "/\(directoryName).asm")!
    CodeWriter(fileURL: outputFileURL, inputFileURL: URL(string: "file://"+directoryPath + "/\(vmFiles[0])")!).writeInit()
    for file in vmFiles{
        let inputFilePath = "file://"+directoryPath + "/\(file)"
        if let parser = Parser(fileURL: URL(string: inputFilePath)!){
            let codeWriter = CodeWriter(fileURL: outputFileURL, inputFileURL: URL(string: inputFilePath)!)
            while parser.hasMoreCommands(){
                parser.advance()
                let commandType = parser.commandType()
                try? "//\(parser.currentCommand)".appendLine(to: outputFileURL)
                if commandType == "Arithmetic"{
                    codeWriter.writeArithmetic(command: parser.currentCommand)
                }else if commandType == "push" || commandType == "pop"{
                    codeWriter.writePushPop(command: commandType, segment: parser.arg1(), index: parser.arg2())
                }else if commandType == "label"{
                    codeWriter.writeLabel(label: parser.arg1())
                }else if commandType == "goto"{
                    codeWriter.writeGoto(label: parser.arg1())
                }else if commandType == "if"{
                    codeWriter.writeIf(label: parser.arg1())
                }else if commandType == "function"{
                    codeWriter.writeFunction(functionName: parser.arg1(), numLocals: parser.arg2())
                }else if commandType == "call"{
                    codeWriter.writeCall(functionName: parser.arg1(), numArgs: parser.arg2(), currentFunctionName: parser.currentFunctionName, callNumber: parser.callNumber)
                }else if commandType == "return"{
                    codeWriter.writeReturn()
                }
            }
        }else{
            print("Unable to read file \(file) in \(directoryName)--Translation Terminated")
            break
        }
    }
}

