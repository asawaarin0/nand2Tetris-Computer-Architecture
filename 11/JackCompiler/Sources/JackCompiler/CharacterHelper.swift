//
//  CharacterHelper.swift
//  JackCompiler
//
//  Created by Arin Asawa on 10/14/20.
//

import Foundation
extension Character
{
    func unicodeScalarCodePoint() -> UInt32
    {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars

        return scalars[scalars.startIndex].value
    }
}
