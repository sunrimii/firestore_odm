# Firestore ODM Fork - 升級說明

這是 sylphxltd/firestore_odm 的 fork，已升級依賴以支援最新的 Firebase 和 Flutter SDK。

## 升級內容

### ✅ 主要升級 (已完成)
- ✅ cloud_firestore: `^5.0.0` → `^6.0.2`
- ✅ cloud_firestore_platform_interface: `^6.5.0` → `^7.0.2`
- ✅ Dart SDK: `^3.8.1` → `^3.9.2`
- ✅ analyzer: `^6.8.0` → `^7.7.1`
- ✅ source_gen: `^2.0.0` → `^3.1.0`
- ✅ build: `^2.3.0` → `^3.1.0`
- ✅ melos: `^6.3.0` → `^7.1.1`
- ✅ very_good_analysis: `^7.0.2` → `^7.1.0`

### ✅ 修復內容
- ✅ **所有編譯錯誤已修復** (之前有 7 個錯誤)
- ✅ Element → Element2 API 遷移完成
- ✅ melos bootstrap 成功運行
- ✅ 代碼可以正常編譯

### ⚠️ 剩餘工作
- ⚠️ 108 個 deprecation warnings（非阻塞性）
- ⚠️ 需要測試 build_runner 生成代碼功能
- ⚠️ 需要在實際應用中測試整合

## 如何在你的應用中使用

在你的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  firestore_odm: 
    git:
      url: https://github.com/sunrimii/firestore_odm.git
      ref: main
      path: packages/firestore_odm
  firestore_odm_annotation:
    git:
      url: https://github.com/sunrimii/firestore_odm.git
      ref: main
      path: packages/firestore_odm_annotation

dev_dependencies:
  firestore_odm_builder:
    git:
      url: https://github.com/sunrimii/firestore_odm.git
      ref: main
      path: packages/firestore_odm_builder
  build_runner: ^2.4.0
```

然後運行：
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 測試狀態

| 測試項目 | 狀態 |
|---------|------|
| melos bootstrap | ✅ 成功 |
| dart analyze (builder) | ✅ 0 errors (有 warnings) |
| build_runner build | ⏳ 待測試 |
| 實際應用整合 | ⏳ 待測試 |

## 技術細節

### Element2 遷移方案
由於 analyzer 7.7.1 和 source_gen 3.1.0 使用新的 Element2 API，但許多內部代碼仍使用舊 Element API，我們採用了以下解決方案：

1. **GeneratorForAnnotatedElement**: 接受 Element2 參數，內部通過 `firstFragment` 轉換為舊 Element
2. **TypeChecker 調用**: 不使用 `TypeChecker.fromRuntime().firstAnnotationOfExact()`，改用直接檢查 `element.metadata` 並調用 `computeConstantValue()`
3. **InvalidGenerationSourceError**: 確保傳遞 Element2 參數而非舊 Element

這種混合方案允許我們在不完全重寫代碼的情況下升級依賴。

## 已知問題

1. **Deprecation Warnings (108個)**:
   - TypeChecker.fromRuntime 已被棄用
   - 舊 Element API 使用（Element, FieldElement, ParameterElement 等）
   - 建議使用 TypeChecker.fromUrl 或 TypeChecker.typeNamed

2. **待驗證功能**:
   - 代碼生成是否正常工作
   - 所有註解處理是否正確
   - 與最新 cloud_firestore 6.0.2 的相容性

## 升級歷程

詳細升級過程請參考 commit history:
1. `47d3c79` - 初始 fork 和依賴升級嘗試
2. `4e1b717` - 使用相容版本 (analyzer 7.7.1, source_gen 3.1.0)
3. `b2e94dc` - 修復所有 Element→Element2 遷移錯誤

## 貢獻

如果發現問題或有改進建議，歡迎提交 issue 或 PR 到：
https://github.com/sunrimii/firestore_odm

---

Original Repository: https://github.com/sylphxltd/firestore_odm
Fork Maintainer: sunrimii
Last Updated: 2025-01-16
