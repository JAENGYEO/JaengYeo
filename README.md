# 쟁여 (JaengYeo)

> 자취생을 위한 식재료 & 생활용품 재고 관리 iOS 앱

바코드, 영수증, AI 사물인식으로 간편하게 상품을 등록하고, 재고 현황을 한눈에 관리하세요.
유통기한 임박 · 재고 부족 알림으로 놓치는 식재료 없이, 위젯으로 홈 화면에서 바로 수량을 조절할 수 있습니다.

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **기간** | 2025.03.31 ~ 2025.05.07 |
| **플랫폼** | iOS 17.0+ (iPhone) |
| **팀** | 손영빈, 한주헌, 김미나 |

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| **Language** | Swift 5.0 |
| **UI** | UIKit + SnapKit (비율 기반 Auto Layout) |
| **Reactive** | RxSwift, RxCocoa, RxRelay, RxKeyboard |
| **이미지** | Kingfisher |
| **로컬 저장소** | CoreData (App Group 공유) |
| **백엔드** | Supabase (Auth, PostgREST, Edge Functions) |
| **인증** | Sign in with Apple + Supabase Auth |
| **AI/ML** | GPT-4o-mini (Vision + Text), Apple Vision Framework, FoundationModels (iOS 26+) |
| **Push 알림** | APNs + Supabase Edge Function + pg_cron |
| **위젯** | WidgetKit + SwiftUI + AppIntent |
| **코드 품질** | SwiftLint |
| **의존성 관리** | Swift Package Manager |

---

## 아키텍처

### MVVM + Coordinator + RxSwift

```
┌─────────────┐    ┌──────────────┐    ┌───────────────┐
│ Coordinator │───→│  ViewModel   │←───│ViewController │
│             │    │              │    │               │
│ - 화면 전환   │    │ - Input      │    │ - lifecycle   │
│ - VM 생성    │    │ - Output     │    │ - View 주입    │
│ - DI 주입    │    │ - transform  │    │ - 바인딩        │
└─────────────┘    └──────┬───────┘    └───────┬───────┘
                          │                    │
                   ┌──────┴──────┐      ┌──────┴──────┐
                   │  Manager /  │      │   XxxView   │
                   │  Repository │      │ (UI 선언,    │
                   │  (Protocol) │      │  레이아웃)    │
                   └─────────────┘      └─────────────┘
```

### 선정 이유

**MVC 대비**
- ViewController가 비대해지는 Massive VC 문제 방지
- ViewModel로 비즈니스 로직을 분리하여 역할 명확화

**Coordinator 도입 이유**
- 복잡한 네비게이션 플로우(탭 전환, 딥링크, 모달) 관리
- ViewController 간 의존성 제거 -- VC는 다음 화면을 알지 못함
- ViewModel 생성 및 의존성 주입을 Coordinator가 전담

**RxSwift 도입 이유**
- Input/Output/transform 패턴으로 ViewModel의 데이터 흐름 단방향화
- UI 이벤트 -> ViewModel -> UI 갱신의 선언적 바인딩
- CoreData 옵저빙(NSFetchedResultsController+Rx)으로 데이터 변경 실시간 반영

---

## 핵심 기능

### 상품 등록 -- 4가지 모드 통합 플로우

바코드 스캔, 영수증 OCR, AI 사물인식, 직접 입력 4가지 등록 경로를 `RegisterFormData` 단일 모델로 통일하여 하나의 플로우(ItemList -> Detail -> Complete)로 처리합니다. 빠른 등록 토글로 상세 입력을 생략할 수 있습니다.

| 모드 | 기술 스택 |
|------|----------|
| 바코드 | AVCaptureMetadataOutput + barcode-lookup Edge Function |
| 영수증 | Apple Vision OCR -> GPT-4o-mini 텍스트 정제 (iOS 26+: FoundationModels 온디바이스) |
| AI 사물인식 | 이미지 압축(512px, 60%) -> gpt-vision Edge Function |
| 직접 입력 | 빈 폼으로 즉시 상세 입력 진입 |

### 오프라인 퍼스트 동기화

CoreData에 즉시 저장하여 오프라인에서도 끊김 없이 동작합니다. `syncStatus` 3가지 상태(synced / pendingUpload / pendingDelete)로 관리하며, NWPathMonitor가 네트워크 복귀를 감지하면 SyncManager가 자동으로 Supabase에 동기화합니다.

```
[오프라인]
등록/수정 -> CoreData 저장 (syncStatus: pendingUpload) -> UI 즉시 반영

[온라인 복귀]
NWPathMonitor 감지 -> SyncManager.synchronize()
  -> pendingUpload: Supabase upsert -> synced
  -> pendingDelete: Supabase soft delete -> 로컬 hard delete
```

### 위젯 (5종)

App Group 공유 CoreData로 앱-위젯 간 데이터를 공유합니다.

| 위젯 | 설명 | 상호작용 |
|------|------|---------|
| 수량 조절 | 프리셋 기반 상품 수량 관리 | AppIntent로 위젯 내 직접 증감 |
| 재고 부족 | 재고 부족 상품 목록 | 딥링크 탭 -> 앱 목록 화면 |
| 유통기한 | 유통기한 임박 상품 목록 | 딥링크 탭 -> 앱 목록 화면 |
| 장바구니 | 구매 예정 상품 목록 | 딥링크 탭 -> 앱 장바구니 |
| 카메라 바로가기 | 등록 모드별 바로 진입 | 딥링크 탭 -> 앱 카메라 |

### Push 알림 -- 서버 APNs + 피보나치 백오프

pg_cron이 매일 3회 Edge Function을 자동 실행하여 APNs로 알림을 발송합니다.

| 시간 (KST) | 알림 타입 | 내용 |
|------------|----------|------|
| 19:00 | expiry_evening | 내일 유통기한 만료 상품 |
| 12:00 | expiry_noon | 오늘 유통기한 만료 상품 |
| 10:00 | low_stock | 재고 부족 상품 (피보나치 백오프) |

- 재고 부족 알림은 [1, 2, 3, 5, 8]일 간격으로 최대 5회 발송 후 중단
- `notification_logs` 테이블로 당일 중복 발송 방지
- 알림 탭 시 딥링크로 해당 목록 화면 이동

### 재고 관리

카테고리(대분류/중분류/소분류) 기반 상품 분류, 수량 증감, 검색(최근 검색어 저장)을 지원합니다. 중분류 커스텀 편집(이름/아이콘 변경)이 가능하며, 상품 상세에서 수정/삭제/장바구니 추가를 처리합니다.

### 장바구니 (구매 예정 목록)

기존 등록 상품 검색 추가 또는 신규 항목 직접 입력이 가능합니다. 구매 확정 시 해당 상품을 재고로 등록하는 플로우와 연결됩니다.

### Sign in with Apple

Supabase Auth와 연동합니다. Keychain 세션 잔존 문제에 대응하는 `clearSessionIfReinstalled` 패턴을 적용했으며, 회원 탈퇴 시 Apple 재인증으로 authorization code를 획득한 뒤 서버 측 토큰을 폐기합니다.

---

## 프로젝트 구조

```
JaengYeo/
├── Application/                    # Coordinator + AppDelegate/SceneDelegate
│   ├── AppCoordinator.swift
│   ├── HomeCoordinator.swift
│   ├── RegisterCoordinator.swift
│   ├── StockCoordinator.swift
│   ├── CartCoordinator.swift
│   └── DeepLink.swift
│
├── View/                           # UI (ViewController + View 분리)
│   ├── Common/                     #   공용 (BaseVC, AlertController, ProductCell)
│   ├── Home/                       #   홈 화면
│   ├── Register/                   #   등록 (카메라, 목록, 상세, 완료)
│   ├── Stock/                      #   재고 (목록, 상세, 검색, 카테고리 편집)
│   ├── Cart/                       #   장바구니 (목록, 추가, 구매 확정)
│   ├── MyPage/                     #   마이페이지 + 위젯 프리셋 관리
│   ├── ItemListView/               #   공용 목록 (미분류/유통기한/재고부족)
│   ├── Login/                      #   Apple 로그인
│   └── OnBoarding/                 #   온보딩 (6페이지)
│
├── ViewModel/                      # 비즈니스 로직 (Input/Output/transform)
│   ├── Stock/
│   ├── Cart/
│   └── MyPage/
│
├── Model/                          # 도메인 모델 + DTO
│   ├── Domain/                     #   CoreData 도메인, Register 모델
│   └── DTO/                        #   CoreData Payload, Supabase DTO
│
├── Data/                           # 로컬 데이터
│   ├── CoreData/                   #   CoreDataManager + Entity
│   └── Receipt/                    #   영수증 OCR 파이프라인
│
├── Network/                        # API 통신 + 동기화
│   ├── AuthManager.swift
│   ├── ProductManager.swift
│   ├── CategoryManager.swift
│   ├── SyncManager.swift
│   └── NotificationManager.swift
│
└── Utils/                          # Extension, Constants

JaengYeoWidget/                     # 위젯 Extension
├── Quantity/                       #   수량 조절 (AppIntent)
├── LowStock/                      #   재고 부족
├── Expiry/                        #   유통기한 임박
├── Cart/                          #   장바구니
├── Camera/                        #   카메라 바로가기
└── Common/                        #   WidgetDataStore, InfoListWidgetView

supabase/                           # 백엔드
├── migrations/                     #   SQL 마이그레이션 (14개)
└── functions/                      #   Edge Function (6개)
    ├── barcode-lookup/             #     바코드 조회 프록시
    ├── gpt-vision/                 #     GPT-4o-mini Vision 프록시
    ├── gemini-vision/              #     Gemini AI 프록시
    ├── send-notifications/         #     APNs 푸시 발송
    ├── sync-device-token/          #     기기 토큰 등록
    └── delete-account/             #     계정 삭제
```
