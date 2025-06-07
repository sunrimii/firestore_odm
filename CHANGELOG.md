# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-07

### Added
- Initial release of Firestore ODM library
- `firestore_odm_annotation` package with runtime annotations and base classes
- `firestore_odm_builder` package with code generation capabilities
- Type-safe Firestore operations with compile-time checks
- Automatic code generation from annotations
- Reactive streams with real-time updates
- Optimistic updates with automatic diff computation
- Transaction support for atomic operations
- Monorepo structure with Melos workspace management
- Comprehensive documentation and examples

### Features
- `@CollectionPath` annotation for defining collection paths
- `@SubcollectionPath` annotation for nested collections
- `FirestoreCollection<T>` base class for type-safe collections
- `FirestoreDocument<T>` base class for document operations
- `FirestoreQuery<T>` base class for querying
- Automatic subscription management for real-time updates
- Built-in caching and performance optimizations
- Support for complex queries and filtering
- Integration with Freezed for immutable data models
- JSON serialization support

### Technical Details
- Built on Cloud Firestore SDK
- Uses build_runner for code generation
- Compatible with Flutter 3.0+ and Dart 3.8+
- Follows clean architecture principles
- Comprehensive error handling
- Memory leak prevention with automatic disposal

### Documentation
- Complete API documentation
- Usage examples and best practices
- Migration guide from manual Firestore usage
- Architecture overview
- Contributing guidelines