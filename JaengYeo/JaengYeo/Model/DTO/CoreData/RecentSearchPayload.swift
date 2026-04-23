//
//  RecentSearchPayload.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/23/26.
//

import Foundation

struct RecentSearchPayload: Hashable {
    let id: UUID
    let keyword: String
    let searchedAt: Date
}
