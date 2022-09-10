import Cocoa
import ArgumentParser
import Foundation


struct JackCompiler:ParsableCommand{
    @Argument()
    var inputPath:String
    mutating func validate() throws {
        //Check if input path is a valid directory/file path
        guard FileManager.default.fileExists(atPath: inputPath) else {throw ValidationError("That is not a valid file/directory path")}
    }
     func run() throws {
        //try to get contents of directory at input file path
        let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: inputPath)
        var jackFileURLS = [URL]()
        //if directContents is nil, the input path was that to a file not a directory
        if let directoryContents = directoryContents{
            for filename in directoryContents{
                if filename.contains(".jack"){
                    let fileUrl = URL(string: "file://"+inputPath+"/"+filename)!
                    jackFileURLS.append(fileUrl)
                }
            }
        }else{
            let fileExtension = inputPath[inputPath.index(after: inputPath.lastIndex(of: ".")!)...inputPath.index(before: inputPath.endIndex)]
            if String(fileExtension) == "jack"{
                jackFileURLS.append(URL(string: "file://"+inputPath)!)
            }
        }
        //If jackFileURLS is empty, it means that the input path is not a path to a jack file or a directory containing jack files
        guard !jackFileURLS.isEmpty else {throw ValidationError("The input path is not a path to a jack file or a directory containing jack files ")}
        var analyzingSuccessful = true
        for url in jackFileURLS{
            let tokenizer = JackTokenizer(inputFileURL: url)!
            let compilationEngine = CompilationEngine(tokenizer: tokenizer, outputFileURL: getOutputURL(for: url))
            guard compilationEngine.analyzingSuccessful else {analyzingSuccessful = false;break}
        }
        print("The analyzing of the file/directory was \(analyzingSuccessful ? "successful":"unsuccessful")")
        
    }
    
    func getOutputURL(for  url:URL)->URL{
        let stringURL = url.absoluteString
        let fileName = String(stringURL[stringURL.index(after: stringURL.lastIndex(of: "/")!)...stringURL.index(before: stringURL.lastIndex(of: ".")!)])+".vm"
        let directoryPath = String(stringURL[stringURL.startIndex...stringURL.lastIndex(of: "/")!])
        return URL(string: directoryPath+fileName)!
    }
}
JackCompiler.main()

