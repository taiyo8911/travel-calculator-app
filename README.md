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
| id | code | name |
|-----|------|------|
| UUID-C1 | USD | 米ドル |
| UUID-C2 | EUR | ユーロ |
| UUID-C3 | GBP | 英ポンド |
| UUID-C4 | AUD | 豪ドル |
| UUID-C5 | THB | タイバーツ |

### Trip モデル
| id | name | currency | exchangeRecords | purchaseRecords |
|-----|------|----------|-----------------|-----------------|
| UUID-1 | アメリカ旅行 | UUID-C1 (USD) | [UUID-E1, UUID-E2] | [UUID-P1, UUID-P2, UUID-P3] |
| UUID-2 | ヨーロッパ周遊 | UUID-C2 (EUR) | [UUID-E3, UUID-E4] | [UUID-P4, UUID-P5, UUID-P6] |
| UUID-3 | タイ旅行 | UUID-C5 (THB) | [UUID-E5] | [UUID-P7, UUID-P8] |
| UUID-4 | イギリス出張 | UUID-C3 (GBP) | [UUID-E6] | [UUID-P9, UUID-P10] |

### ExchangeRecord モデル
| id | date | jpyAmount | displayRate | foreignAmount | actualRate | feePercentage | isHighFee |
|-----|------------|-----------|-------------|---------------|------------|--------------|-----------|
| UUID-E1 | 2025-04-09 | 100000 | 147.0 | 666.67 | 150.0 | 2.04 | 否 |
| UUID-E2 | 2025-04-15 | 50000 | 145.0 | 334.45 | 149.5 | 3.10 | 是 |
| UUID-E3 | 2025-05-01 | 150000 | 160.0 | 909.09 | 165.0 | 3.13 | 是 |
| UUID-E4 | 2025-05-10 | 80000 | 162.0 | 485.44 | 164.8 | 1.73 | 否 |
| UUID-E5 | 2025-07-19 | 100000 | 4.0 | 23809.52 | 4.2 | 5.00 | 是 |
| UUID-E6 | 2025-09-04 | 120000 | 205.0 | 571.43 | 210.0 | 2.44 | 否 |

### PurchaseRecord モデル（旅行別）
#### アメリカ旅行 (USD) の買い物記録
| id | date | foreignAmount | description | jpyAmount (149.83円/USD) |
|-----|------------|--------------|-------------|-----------------------------|
| UUID-P1 | 2025-04-11 | 45.99 | ニューヨーク観光ツアー | 6,890.30円 |
| UUID-P2 | 2025-04-13 | 89.50 | お土産（Tシャツ、マグカップ） | 13,409.79円 |
| UUID-P3 | 2025-04-18 | 120.75 | ディナー at スカイレストラン | 18,091.97円 |

#### ヨーロッパ周遊 (EUR) の買い物記録
| id | date | foreignAmount | description | jpyAmount (165.05円/EUR) |
|-----|------------|--------------|-------------|-----------------------------|
| UUID-P4 | 2025-05-02 | 55.00 | パリ地下鉄チケット | 9,077.73円 |
| UUID-P5 | 2025-05-03 | 145.80 | 美術館入場料とお土産 | 24,064.29円 |
| UUID-P6 | 2025-05-12 | 210.50 | 高級レストランでのディナー | 34,743.03円 |

#### タイ旅行 (THB) の買い物記録
| id | date | foreignAmount | description | jpyAmount (4.2円/THB) |
|-----|------------|--------------|-------------|-----------------------------|
| UUID-P7 | 2025-07-21 | 1250.00 | タイ料理クッキングクラス | 5,250.00円 |
| UUID-P8 | 2025-07-23 | 3500.00 | エレファントサファリツアー | 14,700.00円 |

#### イギリス出張 (GBP) の買い物記録
| id | date | foreignAmount | description | jpyAmount (210.0円/GBP) |
|-----|------------|--------------|-------------|-----------------------------|
| UUID-P9 | 2025-09-06 | 42.50 | ロンドン観光バスツアー | 8,925.00円 |
| UUID-P10 | 2025-09-09 | 85.75 | ビジネスディナー | 18,007.50円 |

### 旅行別集計データ
| 旅行名 | 合計両替額(JPY) | 合計外貨取得額 | 加重平均レート | 合計支出(外貨) | 合計支出(JPY換算) |
|---------|-------------------|-------------------|-----------------|-------------------|----------------------|
| アメリカ旅行 | 150,000円 | 1,001.12 USD | 149.83円/USD | 256.24 USD | 38,392.06円 |
| ヨーロッパ周遊 | 230,000円 | 1,394.53 EUR | 165.05円/EUR | 411.30 EUR | 67,885.05円 |
| タイ旅行 | 100,000円 | 23,809.52 THB | 4.2円/THB | 4,750.00 THB | 19,950.00円 |
| イギリス出張 | 120,000円 | 571.43 GBP | 210.0円/GBP | 128.25 GBP | 26,932.50円 |


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
