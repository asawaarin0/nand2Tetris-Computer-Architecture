

import Foundation


class VMWriter{
    var outputFileURL:URL
    init(outputURL:URL) {
        self.outputFileURL = outputURL
    }
    enum Segment:String{
        case const = "constant"
        case arg = "argument"
        case local = "local"
        case `static` = "static"
        case this = "this"
        case that = "that"
        case pointer = "pointer"
        case temp = "temp"
    }
    enum ArithmeticCommand:String{
        case add = "add"
        case mult = "call Math.multiply 2"
        case div = "call Math.divide 2"
        case sub = "sub"
        case neg = "neg"
        case eq = "eq"
        case gt = "gt"
        case lt = "lt"
        case and = "and"
        case or = "or"
        case not = "not"
    }
    func writePush(segment:Segment,index:Int){
        try? "push \(segment.rawValue) \(index)".appendLine(to: outputFileURL)
    }
    func writePop(segment:Segment,index:Int){
        try? "pop \(segment.rawValue) \(index)".appendLine(to: outputFileURL)
    }
    func writeArithmetic(command:ArithmeticCommand){
        try? "\(command.rawValue)".appendLine(to: outputFileURL)
    }
    func writeLabel(label:String){
        try? "label \(label)".appendLine(to: outputFileURL)
    }
    func writeGoto(label:String){
       try?  "goto \(label)".appendLine(to: outputFileURL)
    }
    func writeIf(label:String){
        try? "if-goto \(label)".appendLine(to: outputFileURL)
    }
    func writeCall(name:String,nArgs:Int){
        try? "call \(name) \(nArgs)".appendLine(to: outputFileURL)
    }
    func writeFunction(name:String,nLocals:Int){
        try? "function \(name) \(nLocals)".appendLine(to: outputFileURL)
    }
    func writeReturn(){
        try? "return".appendLine(to: outputFileURL)
    }
    
    
     
}
