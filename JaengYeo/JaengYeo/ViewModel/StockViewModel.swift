//
//  StockViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/9/26.
//

import Foundation
import RxSwift
import RxRelay

//MARK: - Enum
enum MainCategory {
    case foodstuff
    case Household
}

final class StockViewModel: ViewModelProtocol {
    
    var mainCategory = BehaviorRelay<[String]>(value: ["식재료", "생활용품"])
    
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    func transform(_ input: Input) -> Output {
    
        return Output()
    }
    
}
