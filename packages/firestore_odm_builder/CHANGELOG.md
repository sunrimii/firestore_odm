## 1.1.0

 - **REFACTOR**: transform monolithic FirestoreGenerator into modular architecture. ([a3d79960](https://github.com/sylphxltd/firestore_odm/commit/a3d7996001948b1e9f85396b3451c36139b8cbf7))
 - **REFACTOR**: Remove all hardcoded field names and simplify generator. ([8afa7ecd](https://github.com/sylphxltd/firestore_odm/commit/8afa7ecd03141a8f19aeeecf30cfdfd767009daf))
 - **REFACTOR**: Move basic field builders from generator to core package. ([eb71eaea](https://github.com/sylphxltd/firestore_odm/commit/eb71eaeaaf7eed1ecc06a7303dfcec2998f31556))
 - **REFACTOR**: clean up API naming and remove legacy methods. ([d4045b14](https://github.com/sylphxltd/firestore_odm/commit/d4045b1477c6f9620ee688ba2a8c2cba1de871fb))
 - **FIX**: eliminate duplicate collection classes for same model. ([3142a19a](https://github.com/sylphxltd/firestore_odm/commit/3142a19aaf8f95f7126c151f153759771863ac3b))
 - **FIX**: refactor collection classes to be generic and reusable. ([f873b8be](https://github.com/sylphxltd/firestore_odm/commit/f873b8bec9b694816ff9712660f1020b088f1ff9))
 - **FIX**: Restore path dependencies for proper development workflow. ([d4d555c0](https://github.com/sylphxltd/firestore_odm/commit/d4d555c02101ca1fa2d560e74f360d16b8a8e575))
 - **FIX**: restore nested updater class generation. ([8b32dc96](https://github.com/sylphxltd/firestore_odm/commit/8b32dc967daf8ddf8f3c7bc07a1a0d087b7ea88d))
 - **FIX**: remove hardcoded 'id' references, use dynamic documentIdField. ([135af011](https://github.com/sylphxltd/firestore_odm/commit/135af01160b93c0043239a01574a38b1b1b47ae2))
 - **FIX**: Resolve remaining lint issues in generated code. ([13e6288e](https://github.com/sylphxltd/firestore_odm/commit/13e6288e353448162dfaf3d5563b69d1bb27cb5b))
 - **FIX**: Resolve lint issues in generated code. ([4133293c](https://github.com/sylphxltd/firestore_odm/commit/4133293cf8e3c2525c93ee06832152b0c71e4318))
 - **FIX**: Remove unnecessary null assertion from filter addition in Firestore generator. ([4f6fb294](https://github.com/sylphxltd/firestore_odm/commit/4f6fb2948925a555c1fa484c536a6d0c8f07edac))
 - **FEAT**: implement type-safe aggregate operations and count queries with generated field selectors. ([8e95df5b](https://github.com/sylphxltd/firestore_odm/commit/8e95df5b4a741af567c452fe32c480f8abb3813e))
 - **FEAT**: Introduce schema-based architecture for Firestore ODM. ([de939d90](https://github.com/sylphxltd/firestore_odm/commit/de939d903821a94c962f0d354e982c3b062dfc30))
 - **FEAT**: Successfully publish all packages to pub.dev. ([9e10b6c6](https://github.com/sylphxltd/firestore_odm/commit/9e10b6c61897fc4c876c8d30a3b9f2ff3302edb7))
 - **FEAT**: Complete CI/CD pipeline setup with melos for publishing. ([5f3e440c](https://github.com/sylphxltd/firestore_odm/commit/5f3e440ca1b177a9fa3361792bda02949b3743fe))
 - **FEAT**: convert FirestoreODM constructor to named parameters. ([519b3e14](https://github.com/sylphxltd/firestore_odm/commit/519b3e14d7890bb7be206243633ebbd300fba1d5))
 - **FEAT**: Add support for automatic document ID detection in models. ([6b0c1101](https://github.com/sylphxltd/firestore_odm/commit/6b0c1101d79dfe6c1678367f94754528217e0b89))
 - **FEAT**: unify Collection annotation to support multiple collection paths. ([9fbb73b6](https://github.com/sylphxltd/firestore_odm/commit/9fbb73b69385e2f1ed1fece91299102c3a3bd1c4))
 - **FEAT**: implement multiple @Collection annotations with subcollection support. ([10a9564b](https://github.com/sylphxltd/firestore_odm/commit/10a9564bde3d90a4caa4101d7c88bc03414f4233))
 - **FEAT**: add comprehensive @Collection validation system. ([12659528](https://github.com/sylphxltd/firestore_odm/commit/126595284c0e21d8ffb4cb5f6a46e75e1e17660d))
 - **FEAT**: refactor to unified @Collection annotation with subcollection support. ([c4330d39](https://github.com/sylphxltd/firestore_odm/commit/c4330d39a898bb6c8caaffffcfa7b2ff6e88cfdc))
 - **FEAT**: add @DocumentIdField annotation support. ([9cfb884d](https://github.com/sylphxltd/firestore_odm/commit/9cfb884d59d8922ff2b64e819c05f404575c365e))
 - **FEAT**: Remove legacy orderBy methods from implementation and tests. ([e77a6349](https://github.com/sylphxltd/firestore_odm/commit/e77a6349cf364125d3e31b82bc0e8ad394af6817))
 - **FEAT**: Update test cases to support mixed update syntax and update README. ([5785fc80](https://github.com/sylphxltd/firestore_odm/commit/5785fc8055ce297358a1e2050b79b3b6b94e2c83))
 - **FEAT**: complete Firestore ODM library implementation. ([f7b0da36](https://github.com/sylphxltd/firestore_odm/commit/f7b0da366e149110f855e69eacbdcfbcfa0bc19c))
 - **FEAT**: implement chained updates and enhanced ODM features. ([59460a10](https://github.com/sylphxltd/firestore_odm/commit/59460a1083e26efbaa749ea56fb8e2d97b915e95))
 - **FEAT**: implement nested field updates with copyWith-style API. ([a968695a](https://github.com/sylphxltd/firestore_odm/commit/a968695a9e5dfb1c8ae3790877651b7d3782d804))
 - **FEAT**: comprehensive testing of complex data types and extension methods. ([56ff7e93](https://github.com/sylphxltd/firestore_odm/commit/56ff7e936abac6ae8995908ecca880df6795be8a))
 - **FEAT**: implement RxDB-style API with atomic operations. ([08af4f52](https://github.com/sylphxltd/firestore_odm/commit/08af4f52da200d4522380c95954fe25311b6df46))
 - **FEAT**: restructure as monorepo with strong-typed Firestore ODM. ([b9e6ced0](https://github.com/sylphxltd/firestore_odm/commit/b9e6ced07c38c798ec594a0c96292c86888422f7))
 - **FEAT**: Complete Firestore ODM example with working code generation. ([77f515bf](https://github.com/sylphxltd/firestore_odm/commit/77f515bf93bcfb32010fe33ab1988a6fc7623055))
 - **FEAT**: Convert Firestore ODM to monorepo library. ([279e3547](https://github.com/sylphxltd/firestore_odm/commit/279e35473d592307bec352a9af359a798f2cc224))

# Changelog

## [1.0.0] - 2025-01-09

### Added
- Initial release of firestore_odm_builder
- Code generation for @Collection and @SubCollection annotations
- Type-safe query builder generation
- Automatic serialization/deserialization code generation
- Real-time snapshot support generation
- Transaction and batch operation support
- Comprehensive error handling and validation