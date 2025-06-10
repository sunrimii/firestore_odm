## 1.1.0

 - **REFACTOR**: enhance documentation structure with quick navigation and feature overview. ([8c21f3c6](https://github.com/sylphxltd/firestore_odm/commit/8c21f3c63adf47079d53afa47faaf7e00cef132f))
 - **REFACTOR**: implement SubscribeOperations interface and unify stream handling. ([b21b4de4](https://github.com/sylphxltd/firestore_odm/commit/b21b4de47a27f1812ea9368399221105d487715e))
 - **REFACTOR**: unify stream handling by renaming 'snapshots' to 'stream' across aggregate and query implementations. ([d637ed91](https://github.com/sylphxltd/firestore_odm/commit/d637ed91f1c0e922e7fb6dbb91214af200934570))
 - **REFACTOR**: enhance aggregate query execution and result handling with native Firestore support. ([a6e46f7f](https://github.com/sylphxltd/firestore_odm/commit/a6e46f7f11520ef17a98c11f4750450adc8b1628))
 - **REFACTOR**: rename 'snapshots' to 'stream' for consistency across interfaces and implementations. ([ec6c6e54](https://github.com/sylphxltd/firestore_odm/commit/ec6c6e54790ec3700e1c394872a9fdad91beddd1))
 - **REFACTOR**: rename 'changes' to 'snapshots' for clarity in subscription interfaces. ([89d0c637](https://github.com/sylphxltd/firestore_odm/commit/89d0c6373c889904ae6ff607010e0c0e4a0df063))
 - **REFACTOR**: remove special timestamp handling from Firestore ODM classes. ([8d5658af](https://github.com/sylphxltd/firestore_odm/commit/8d5658af7cdbde0e836f3f7c507865e8b4924e27))
 - **REFACTOR**: Remove all hardcoded field names and simplify generator. ([8afa7ecd](https://github.com/sylphxltd/firestore_odm/commit/8afa7ecd03141a8f19aeeecf30cfdfd767009daf))
 - **REFACTOR**: reduce generated code by 60% using filter extensions and enums. ([dd61bc2d](https://github.com/sylphxltd/firestore_odm/commit/dd61bc2db63ccccb899728cf60eeb455657db650))
 - **REFACTOR**: Move basic field builders from generator to core package. ([eb71eaea](https://github.com/sylphxltd/firestore_odm/commit/eb71eaeaaf7eed1ecc06a7303dfcec2998f31556))
 - **REFACTOR**: remove deprecated update method for clarity and maintainability. ([19ed3f08](https://github.com/sylphxltd/firestore_odm/commit/19ed3f081bc50d4a20f178eca3e61de31837fe82))
 - **FIX**: Restore path dependencies for proper development workflow. ([d4d555c0](https://github.com/sylphxltd/firestore_odm/commit/d4d555c02101ca1fa2d560e74f360d16b8a8e575))
 - **FIX**: correct method roles - modify() non-atomic vs incrementalModify() atomic. ([d515b215](https://github.com/sylphxltd/firestore_odm/commit/d515b2151d5e36e2decbf070ec1bec11b590ff2d))
 - **FEAT**: implement type-safe aggregate operations and count queries with generated field selectors. ([8e95df5b](https://github.com/sylphxltd/firestore_odm/commit/8e95df5b4a741af567c452fe32c480f8abb3813e))
 - **FEAT**: add collection-level operations for insert, update, and upsert. ([23bae871](https://github.com/sylphxltd/firestore_odm/commit/23bae871dd7342ceca9473587aeb9169a38df08d))
 - **FEAT**: Introduce schema-based architecture for Firestore ODM. ([de939d90](https://github.com/sylphxltd/firestore_odm/commit/de939d903821a94c962f0d354e982c3b062dfc30))
 - **FEAT**: Successfully publish all packages to pub.dev. ([9e10b6c6](https://github.com/sylphxltd/firestore_odm/commit/9e10b6c61897fc4c876c8d30a3b9f2ff3302edb7))
 - **FEAT**: Complete CI/CD pipeline setup with melos for publishing. ([5f3e440c](https://github.com/sylphxltd/firestore_odm/commit/5f3e440ca1b177a9fa3361792bda02949b3743fe))
 - **FEAT**: convert FirestoreODM constructor to named parameters. ([519b3e14](https://github.com/sylphxltd/firestore_odm/commit/519b3e14d7890bb7be206243633ebbd300fba1d5))
 - **FEAT**: Add callable collection syntax and fix serialization. ([4632a55d](https://github.com/sylphxltd/firestore_odm/commit/4632a55d0fb0d1df8c761ae3f15bf7b9bdc46336))
 - **FEAT**: add @DocumentIdField annotation support. ([9cfb884d](https://github.com/sylphxltd/firestore_odm/commit/9cfb884d59d8922ff2b64e819c05f404575c365e))
 - **FEAT**: Update test cases to support mixed update syntax and update README. ([5785fc80](https://github.com/sylphxltd/firestore_odm/commit/5785fc8055ce297358a1e2050b79b3b6b94e2c83))
 - **FEAT**: unify atomic operations support across modify methods. ([4df3af73](https://github.com/sylphxltd/firestore_odm/commit/4df3af7309ddfa331830c3cce3ba4b40f8486090))
 - **FEAT**: complete Firestore ODM library implementation. ([f7b0da36](https://github.com/sylphxltd/firestore_odm/commit/f7b0da366e149110f855e69eacbdcfbcfa0bc19c))
 - **FEAT**: implement chained updates and enhanced ODM features. ([59460a10](https://github.com/sylphxltd/firestore_odm/commit/59460a1083e26efbaa749ea56fb8e2d97b915e95))
 - **FEAT**: implement RxDB-style API with atomic operations. ([08af4f52](https://github.com/sylphxltd/firestore_odm/commit/08af4f52da200d4522380c95954fe25311b6df46))
 - **FEAT**: restructure as monorepo with strong-typed Firestore ODM. ([b9e6ced0](https://github.com/sylphxltd/firestore_odm/commit/b9e6ced07c38c798ec594a0c96292c86888422f7))
 - **DOCS**: enhance documentation for limit and limitToLast methods with usage limitations. ([7109d26b](https://github.com/sylphxltd/firestore_odm/commit/7109d26b75425cab6501b2ab99d4dc0bc4068586))

# Changelog

## [1.0.0] - 2025-01-09

### Added
- Initial release of firestore_odm
- Type-safe Firestore operations
- Automatic serialization/deserialization
- Query builder with IntelliSense support
- Real-time updates with snapshots
- Subcollection support
- Transaction and batch operation support
- Comprehensive documentation and examples