## 2.2.2

 - **FIX**: IMap bug fixes and patch operations in UpdateBuilder. ([579476a4](https://github.com/sylphxltd/firestore_odm/commit/579476a4e9039fb1416ec8e2ac271c7e9cb3a3a6))

## 2.2.1

 - **REFACTOR**: remove debug print statements from model analysis and firestore generator. ([98217a66](https://github.com/sylphxltd/firestore_odm/commit/98217a662835489eddfe034aa3a48c6b5171c92c))

## 2.2.0

 - **REFACTOR**: remove unused variables and simplify field analysis in ModelAnalyzer. ([1032f4e0](https://github.com/sylphxltd/firestore_odm/commit/1032f4e0e746c7965ab24491539747c9df427d60))
 - **FIX**: specify version for firestore_odm_annotation dependency in pubspec.yaml. ([a768af95](https://github.com/sylphxltd/firestore_odm/commit/a768af9501fab24a4b9680109bd089b22465bfa5))
 - **FEAT**: Add comprehensive batch operations support. ([802a629b](https://github.com/sylphxltd/firestore_odm/commit/802a629b2efe4e8c95b8efeb9766dff0b69f62d3))
 - **FEAT**: refactor project folder structure. ([d4907075](https://github.com/sylphxltd/firestore_odm/commit/d49070757a19ea643d73e2aa0664754f0c67da44))
 - **DOCS**: Update all documentation URLs to GitHub Pages. ([321ccdcd](https://github.com/sylphxltd/firestore_odm/commit/321ccdcd10f31374f6cd5b955fa3b7cb2d7f17fa))
 - **DOCS**: refactor and centralize README.md. ([7c121c62](https://github.com/sylphxltd/firestore_odm/commit/7c121c62981001803322ff5af1e2bb3f4593c46c))

## 2.1.0

 - **FEAT**: add json_annotation dependency to pubspec.yaml. ([f2c7f28d](https://github.com/sylphxltd/firestore_odm/commit/f2c7f28d17e698caeaad53777a7ce718534b1d03))

## 2.0.1

 - **REFACTOR**: code formatting and improve readability across multiple files. ([4a7876b7](https://github.com/sylphxltd/firestore_odm/commit/4a7876b7a16fb389301b9bdb924b24b9e4bbbde6))
 - **REFACTOR**: update Firestore ODM builders to enhance type handling and improve code structure. ([841f5073](https://github.com/sylphxltd/firestore_odm/commit/841f5073c553c3793d4c8f1e4bf887663ba28ff6))
 - **REFACTOR**: update to use element2 API for improved type handling. ([77260aa7](https://github.com/sylphxltd/firestore_odm/commit/77260aa7d8ffcb22fadd8414e9e4a89aed8ffcf9))
 - **REFACTOR**: firestore ODM code generation to utilize ModelAnalysis. ([1e82daab](https://github.com/sylphxltd/firestore_odm/commit/1e82daaba984ebd3d3d3ec15d80d855e29869221))
 - **REFACTOR**: refactor and clean up code across multiple files. ([cc44c322](https://github.com/sylphxltd/firestore_odm/commit/cc44c322b43fb72bdeebb20b0a87ccd8fcb64607))

## 2.0.0

> Note: This release has breaking changes.

 - **REFACTOR**: remove TupleAggregateQuery and UpdateBuilder, introduce utility functions for Firestore data processing. ([8a224de8](https://github.com/sylphxltd/firestore_odm/commit/8a224de8d9dea2cc9938c707f53ef4210965d47a))
 - **FIX**: implement defer writes pattern to resolve read-write ordering. ([cf1ae907](https://github.com/sylphxltd/firestore_odm/commit/cf1ae907eb91b926bbf8e0b116e7dc3e5e72da5d))
 - **FEAT**: enhance type analysis with robust iterable and map support in generators. ([0d4ed7bf](https://github.com/sylphxltd/firestore_odm/commit/0d4ed7bf835eae141783b5194c9ddd01dbbd31f4))
 - **FEAT**: add map operations, bulk delete, and collection bulk operations with comprehensive testing. ([d5612029](https://github.com/sylphxltd/firestore_odm/commit/d5612029e4c662d9054716a85f19076defc6e14a))
 - **FEAT**: Enhance transaction support in Firestore ODM. ([5ba0b618](https://github.com/sylphxltd/firestore_odm/commit/5ba0b618605f8e8c28ae6d20234de55ee26e1d0d))
 - **FEAT**: Implement pagination support in Firestore ODM. ([6abde897](https://github.com/sylphxltd/firestore_odm/commit/6abde8976e51ec63cededee286b750e85ba6dd3a))
 - **FEAT**: implement callable update and order by instances to reduce generated code. ([cf16cea8](https://github.com/sylphxltd/firestore_odm/commit/cf16cea8a10fddd89f88a3fc6063cff5b5c9b2d9))
 - **BREAKING** **FEAT**: add aggregation and pagination support with builder-to-selector refactor. ([8978198c](https://github.com/sylphxltd/firestore_odm/commit/8978198c704dc3e8600ac6f5ffdcd64ae090352c))

## 1.1.2

 - **REFACTOR**: remove unused _getSingularName method. ([8020f9e1](https://github.com/sylphxltd/firestore_odm/commit/8020f9e1dfbca4635ebc964468003fd500239134))
 - **REFACTOR**: remove obsolete document access method generation. ([09a25af4](https://github.com/sylphxltd/firestore_odm/commit/09a25af416f918108c076777f408943b31aabaf9))
 - **REFACTOR**: implement callable filter instances to reduce generated code. ([a19b2f11](https://github.com/sylphxltd/firestore_odm/commit/a19b2f11708ff2a74ccc0cfa0c7055e6bf5beb81))
 - **REFACTOR**: integrate ModelConverter for data transformation across services. ([90979671](https://github.com/sylphxltd/firestore_odm/commit/90979671500403715b910e436ba2108264efc1d3))
 - **REFACTOR**: remove local path references to firestore_odm_annotation. ([48b84db7](https://github.com/sylphxltd/firestore_odm/commit/48b84db75f4947c122bc57a7090d716b9127dedd))
 - **REFACTOR**: remove unused imports and obsolete schema generation method. ([86c0525a](https://github.com/sylphxltd/firestore_odm/commit/86c0525acdd3b91125fdec12d1b1007b02dd2bbb))
 - **REFACTOR**: simplify CollectionInfo and remove unused suffix generation. ([9087b3d1](https://github.com/sylphxltd/firestore_odm/commit/9087b3d1adee124ff461271a13cf5f24d652ea9f))

## 1.1.1

 - **REFACTOR**: improve schema class name generation and add assigned value extraction. ([997aa36a](https://github.com/sylphxltd/firestore_odm/commit/997aa36a53c6c740532ccb3923be9f11e7420aed))

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