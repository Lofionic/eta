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

/*
func filterByRegex(_ regexString: String) -> Observable<String?> {
	return Observable.delay(<#T##self: Observable<_>##Observable<_>#>)
	
	return Observable.create { observable in
		DispatchQueue.global(qos: .userInteractive).async {
			if let range = self.range(of: regexString, options: .regularExpression) {
				DispatchQueue.main.async {
					observable.onNext(String(self[range]))
				}
			} else {
				DispatchQueue.main.async {
					observable.onNext(nil)
				}
			}
		}
		
		return Disposables.create()
	}
}
*/

public extension ObservableType where Element == String? {
	func regex(_ regexString: String) -> Observable<String?> {
		return map { string -> String? in
			guard let string = string else { return nil }
			if let range = string.range(of: regexString, options: .regularExpression) {
				return String(string[range])
			} else {
				return nil
			}
		}
	}
}

public extension SharedSequence where Element == Bool {
    func not() -> SharedSequence<SharingStrategy, Bool> {
        return map { !$0 }
    }
}
