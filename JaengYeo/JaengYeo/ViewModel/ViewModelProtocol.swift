//
//  ViewModelProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//

protocol ViewModelProtocol {
    associatedtype Input
    associatedtype Output
    
    func transform(_ input: Input) -> Output
}
