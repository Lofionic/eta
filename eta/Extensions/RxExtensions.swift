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

public extension ObservableType where Element == String {
    func lowercased() -> Observable<String> {
        return map { $0.lowercased() }
    }
}

public extension ObservableType where Element == String? {
    func regex(_ regexString: String) -> Observable<String?> {
        return map { string -> String? in
            guard let string = string else { return nil }
            if let range = string.range(of: regexString, options: .regularExpression) {
                return String(string[range]) == string ? string : nil
            } else {
                return nil
            }
        }
    }
	
	func lowercased() -> Observable<String?> {
		return map { $0?.lowercased() }
	}
    
    func isValid(_ regexString: String) -> Observable<Bool> {
        return regex(regexString).map { $0 != nil }
    }
}

public extension SharedSequence where Element == Bool {
    func not() -> SharedSequence<SharingStrategy, Bool> {
        return map { !$0 }
    }
}
