
import Foundation


class SymbolTable{
    
    enum Kind:String{
        case `static` = "static"
        case field = "this"
        case arg = "argument"
        case `var` = "local"
        case none
    }
    
    struct SymbolInfo{
        var type:String
        var kind:Kind
        var index:Int
    }
    
    
    var classSymbolTable = [String:SymbolInfo]()
    var subroutineSymbolTable = [String:SymbolInfo]()
    
    
    func startSubroutine(){
        subroutineSymbolTable.removeAll()
    }
    func define(name:String,type:String,kind:Kind){
        if kind == .static || kind == .field{
            classSymbolTable[name] = SymbolInfo(type: type, kind: kind, index: varCount(kind: kind))
        }else{
            subroutineSymbolTable[name] = SymbolInfo(type: type, kind: kind,index: varCount(kind: kind))
        }
    }
    
    func varCount(kind:Kind)->Int{
        if kind == .static || kind == .field{
            return classSymbolTable.values.filter { (symbolInfo) -> Bool in
                symbolInfo.kind == kind
            }.count
        }else{
            return subroutineSymbolTable.values.filter { (symbolInfo) -> Bool in
                 symbolInfo.kind == kind
            }.count
        }
    }
    
    func kindOf(name:String)->Kind{
        if let kind = subroutineSymbolTable[name]?.kind{
            return kind
        }else if let kind = classSymbolTable[name]?.kind{
            return kind
        }else{
            return .none
        }
    }
    
    func typeOf(name:String)->String{
        if let type = subroutineSymbolTable[name]?.type{
            return type
        }else if let type = classSymbolTable[name]?.type{
            return type
        }else{
            return "none"
        }
    }
    
    func indexOf(name:String)->Int{
        if let index = subroutineSymbolTable[name]?.index{
            return index
        }else if let index = classSymbolTable[name]?.index{
            return index
        }else{
            return -1
        }
    }
}

