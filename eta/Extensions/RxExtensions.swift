//
//  Created by Lofionic ©2021
//

import RxCocoa
import RxSwift



public extension SharedSequence where Element == String? {
    func isNotEmpty() -> SharedSequence<SharingStrategy, Bool> {
        return map { value in
            guard let value = value else {
                return false
            }
            return !value.isEmpty
        }
    }
}


public extension SharedSequence where Element == Bool {
    func not() -> SharedSequence<SharingStrategy, Bool> {
        return map { !$0 }
    }
}

