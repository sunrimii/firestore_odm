# 🧪 Firestore ODM Test Architecture

本測試套件採用分層架構設計，確保全面測試覆蓋和清晰的組織結構。

## 📁 測試目錄結構

```
test/
├── core/                           # 核心功能測試
│   ├── basic_operations_test.dart  # 基本 CRUD 操作
│   ├── document_id_test.dart       # Document ID 字段功能
│   ├── update_operations_test.dart # 更新操作（Array/Modify/Incremental）
│   └── query_operations_test.dart  # 查詢操作與過濾器
├── features/                       # 功能特性測試
│   ├── multi_collection_test.dart  # 多集合支援
│   ├── bulk_operations_test.dart   # 批量操作
│   └── realtime_operations_test.dart # 即時更新（Document Streams）
├── advanced/                       # 進階測試
│   ├── error_handling_test.dart    # 錯誤處理與邊界條件
│   └── architecture_validation_test.dart # 架構驗證與效能
└── widget_test.dart               # Flutter 預設測試
```

## 🎯 測試分類說明

### 🚀 Core Tests (核心功能測試)
驗證 Firestore ODM 的基本功能是否正常運作：

#### Basic Operations Test
- **目的**: 驗證基本 CRUD 操作
- **涵蓋**: 創建、讀取、更新、刪除文檔
- **重點**: ODM 初始化、基本查詢、數據轉換

#### Document ID Test  
- **目的**: 驗證 Document ID 字段功能
- **涵蓋**: 明確註解、自動檢測、查詢支援、Upsert 操作
- **重點**: `@DocumentIdField` 註解與自動 ID 檢測

#### Update Operations Test
- **目的**: 驗證三種更新方法的正確性
- **涵蓋**: Array-style、Modify、Incremental Modify
- **重點**: 原子操作、嵌套更新、伺服器時間戳

#### Query Operations Test
- **目的**: 驗證查詢功能的完整性
- **涵蓋**: 基本過濾、數組操作、嵌套字段、邏輯運算、排序與限制
- **重點**: 類型安全查詢、複合條件

### ✨ Feature Tests (功能特性測試)
測試 ODM 的進階功能特性：

#### Multi-Collection Test
- **目的**: 驗證多集合架構的正確性
- **涵蓋**: 根集合、子集合、跨集合操作、類型安全
- **重點**: Schema 基礎架構、統一模型支援

#### Bulk Operations Test
- **目的**: 驗證批量操作的效能與正確性
- **涵蓋**: 批量 Modify、Incremental Modify、目標操作、效能測試
- **重點**: 大規模數據處理、原子操作檢測

#### Realtime Operations Test
- **目的**: 驗證即時更新功能
- **涵蓋**: 文檔串流、集合查詢串流、訂閱管理
- **重點**: 即時數據同步、並發更新、訂閱生命週期

### 🔧 Advanced Tests (進階測試)
測試系統的穩定性、錯誤處理和架構設計：

#### Error Handling Test
- **目的**: 驗證錯誤處理機制的完整性
- **涵蓋**: 無效輸入、邊界條件、例外情況、數據完整性
- **重點**: 防禦式程式設計、優雅的錯誤處理

#### Architecture Validation Test
- **目的**: 驗證系統架構設計的正確性
- **涵蓋**: Schema 分析、集合處理、高效生成、可擴展性
- **重點**: 生成器邏輯驗證、效能基準測試


## 🛡️ 測試覆蓋範圍

### ✅ 正向測試案例
- **基本功能**: 所有 CRUD 操作正常工作
- **查詢功能**: 各種過濾條件和邏輯運算
- **更新操作**: 三種更新方法的正確行為
- **多集合**: 不同集合路徑的模型使用
- **批量操作**: 大規模數據處理
- **即時更新**: 文檔和集合的串流監聽

### ❌ 負向測試案例  
- **無效輸入**: 空文檔 ID、null 值、極端值
- **邊界條件**: 大型文檔、高頻更新、並發操作
- **錯誤情況**: 不存在的文檔、交易回滾、網路錯誤
- **效能限制**: 記憶體使用、響應時間、批量處理

### 🔍 架構驗證
- **Schema 處理**: 集合識別、關係處理、統一驗證
- **生成器效率**: 預分析數據、避免即時收集、高效生成
- **類型安全**: 編譯時驗證、模型轉換、集合類型映射
- **可擴展性**: 多模型支援、效能一致性、職責分離

## 🚀 執行測試

### 執行特定類別測試
```bash
# 核心功能測試
dart test test/core/

# 功能特性測試  
dart test test/features/

# 進階測試
dart test test/advanced/
```

### 執行所有測試
```bash
# 執行所有測試 (推薦)
flutter test

# 或使用 dart test
dart test
```

### 測試報告
```bash
# 生成覆蓋率報告
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📋 測試數據管理

所有測試使用 `FakeFirebaseFirestore` 進行隔離測試：
- **獨立性**: 每個測試都有獨立的 Firestore 實例
- **可重複性**: 測試結果可重複且可預測
- **速度**: 不需要真實的網路連接
- **安全性**: 不會影響真實的 Firestore 數據

## 🎯 測試最佳實踐

1. **命名規範**: 測試名稱清楚描述測試目的
2. **組織結構**: 使用 `group()` 進行邏輯分組
3. **設置與清理**: 在 `setUp()` 中初始化測試環境
4. **斷言明確**: 使用具體的斷言而非模糊檢查
5. **覆蓋全面**: 包含正向和負向測試案例
6. **效能考慮**: 包含效能基準測試
7. **文檔完整**: 每個測試都有清楚的目的說明

## 🔄 持續改進

這個測試架構設計為可擴展的：
- **新功能**: 在相應目錄下添加新測試文件
- **新模型**: 在現有測試中添加新模型的測試案例
- **新場景**: 在適當的測試類別中添加新的測試場景
- **效能**: 持續監控和改進效能基準測試

測試是確保 Firestore ODM 穩定性和可靠性的關鍵，這個架構確保我們能夠全面且有效地驗證系統的各個方面。