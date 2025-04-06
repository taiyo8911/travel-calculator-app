# travel-calculator-app
海外旅行時の両替記録と買い物記録を管理し、レートや支出金額を日本円で把握できる旅行用金銭管理アプリ


## 主な機能
### 旅行管理
* 複数の旅行を作成・管理
* 旅行ごとに通貨を設定
* 旅行期間の設定
  
### 両替記録
* 両替した日本円と受け取った外貨の記録
* 両替所の表示レートと実質レートの計算
* 手数料率の自動計算と高手数料の警告表示
* 両替記録の一覧表示、追加、編集、削除

### 買い物記録
* 外貨での支出記録
* 買い物内容の説明記録
* 加重平均レートを使った日本円換算額の計算
* 買い物記録の一覧表示、追加、編集、削除

### 集計機能
* 旅行全体の両替総額
* 加重平均レートの計算
* 買い物総額（外貨・日本円）

## アプリ構成
アプリはMVVMアーキテクチャに基づいて設計。SwiftUIを使用して構築。

## モデルサンプルデータ
### Currency モデル


## ファイル構成
```
TravelCalculator/
├── App/
│   └── TravelCalculatorApp.swift  // アプリのエントリーポイント
|   └── ContentView.swift          // メインコンテンツビュー
│
├── Models/
│   ├── Trip.swift                 // 旅行モデル
│   ├── Currency.swift             // 通貨モデル
│   ├── ExchangeRecord.swift       // 両替記録モデル
│   └── PurchaseRecord.swift       // 買い物記録モデル
│
├── ViewModels/
│   └── TravelCalculatorViewModel.swift  // メインビューモデル
│
├── Views/
│   ├── Trips/
│   │   ├── TripListView.swift     // 旅行一覧画面
│   │   ├── AddTripView.swift      // 旅行追加画面
│   │   └── TripDetailView.swift   // 旅行詳細画面
│   │
│   ├── Exchange/
│   │   ├── ExchangeListView.swift // 両替履歴画面
│   │   ├── AddExchangeView.swift  // 両替追加画面
│   │   └── EditExchangeView.swift // 両替編集画面
│   │
│   ├── Purchase/
│   │   ├── PurchaseListView.swift // 買い物履歴画面
│   │   ├── AddPurchaseView.swift  // 買い物追加画面
│   │   └── EditPurchaseView.swift // 買い物編集画面
│   │
│   ├── Components/
│   │   ├── SummaryCard.swift      // 集計カードコンポーネント
│   │   ├── ExchangeCard.swift     // 両替カードコンポーネント
│   │   └── PurchaseCard.swift     // 買い物カードコンポーネント
│   │
│   └── Settings/
│       └── SettingsView.swift     // 設定画面
│
└── Utilities/
    ├── CurrencyFormatter.swift    // 通貨フォーマッタ
    └── FlagEmoji.swift            // 国旗絵文字ユーティリティ
```
