//
//  SyncManagerProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

protocol SyncManagerProtocol {
    
    // 네트워크 상태 감지 및 온라인 복귀 시 동기화
    func networkCheck()
    // 동기화 (pending_upload -> 서버 반영, pending_delete -> 서버 소프트 삭제)
    @MainActor func synchronize() async
    // 네트워크 상태가 true일 경우 바로 동기화
    func syncIfConnected()
}
