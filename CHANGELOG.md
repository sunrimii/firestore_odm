# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-07

### 🎉 Initial Release

This is the first stable release of Firestore ODM, a powerful type-safe Object Document Mapper for Firestore.

### ✨ Added

#### Core Features
- **Type-Safe Collections**: Automatically generated collection classes with full type safety
- **Type-Safe Documents**: Document operations with compile-time validation
- **Advanced Querying**: Method-chained queries with auto-completion support
- **Chained Updates**: copyWith-style nested field updates with infinite depth support
- **Code Generation**: Automatic generation of ODM classes from Freezed models

#### Chained Update API
- **Multi-Level Nesting**: Support for unlimited nesting depth with full type safety
- **copyWith-Style Syntax**: Intuitive API similar to Freezed's copyWith method
- **Compile-Time Validation**: Catch errors at compile time, not runtime
- **Auto-Completion**: Full IDE support with intelligent code completion

#### Query System
- **Method Chaining**: Fluent API for building complex queries
- **Type-Safe Filters**: where{Field} methods with proper type checking
- **Sorting Support**: orderBy{Field} methods with ascending/descending options
- **Pagination**: Built-in support for limit, startAfter, and other pagination methods

#### Architecture
- **Monorepo Structure**: Clean separation of concerns across multiple packages
- **Package Organization**:
  - `firestore_odm`: Core runtime library
  - `firestore_odm_annotation`: Annotations for code generation
  - `firestore_odm_builder`: Code generator implementation

### 🔧 Technical Implementation

#### Code Generation
- **Annotation Processing**: Uses `@CollectionPath` to identify Firestore collections
- **Freezed Integration**: Seamless integration with Freezed data classes
- **Builder Pattern**: Generates update builders for nested field updates
- **Type Analysis**: Deep analysis of nested types for complete type safety

#### Generated Classes
- **Collection Classes**: `{Model}Collection` with query mixins
- **Document Classes**: `{Model}Document` with update capabilities
- **Query Classes**: `{Model}Query` with method chaining
- **Update Builders**: `{Model}UpdateBuilder` for chained updates

#### Features
- **Nested Type Detection**: Automatically detects and generates builders for nested custom types
- **Built-in Type Filtering**: Skips built-in types (String, int, bool, etc.) for cleaner generation
- **Recursive Generation**: Supports deeply nested structures with recursive builder generation
- **Import Management**: Automatic import generation for nested types

### 📚 Documentation

#### Examples
- **Basic CRUD Operations**: Complete examples of Create, Read, Update, Delete operations
- **Advanced Querying**: Complex query examples with multiple conditions
- **Chained Updates**: Comprehensive examples of nested field updates
- **Real-World Scenarios**: Practical examples for social media, gaming, and business apps

#### Demo Files
- `final_demo.dart`: Complete demonstration of all features
- `test_chained_updates.dart`: Focused testing of chained update API
- `test_nested_updates_fixed.dart`: Fixed version of nested update tests

### 🎯 Benefits

#### Developer Experience
- **Type Safety**: Full compile-time type checking eliminates runtime errors
- **Auto-Completion**: Excellent IDE support with intelligent suggestions
- **Refactoring Safe**: Changes to data models automatically propagate through generated code
- **Clean Syntax**: Intuitive API that's easy to read and maintain

#### Performance
- **Efficient Queries**: Optimized query generation with minimal overhead
- **Tree Shaking**: Generated code is tree-shakable for smaller bundle sizes
- **Minimal Runtime**: Lightweight runtime with most work done at compile time

#### Maintainability
- **Reduced Boilerplate**: Eliminates repetitive Firestore code
- **Consistent Patterns**: Enforces consistent data access patterns across the app
- **Error Prevention**: Prevents common Firestore mistakes through type safety

### 🔍 Comparison with Traditional Firestore

#### Before (Traditional Firestore)
```dart
// ❌ Error-prone string literals
await userDoc.updateFields({
  'profile.bio': 'Updated bio',
  'profile.followers': 200,
  'profile.socialLinks.github': 'new-username',
});

// ❌ No type checking
final users = await FirebaseFirestore.instance
    .collection('users')
    .where('age', isGreaterThan: 18)
    .where('isPremium', isEqualTo: true)
    .get();
```

#### After (Firestore ODM)
```dart
// ✅ Type-safe chained updates
await userDoc.update.profile(
  bio: 'Updated bio',
  followers: 200,
  socialLinks: {'github': 'new-username'},
);

// ✅ Type-safe queries with auto-completion
final users = await odm.users
    .whereAge(isGreaterThan: 18)
    .whereIsPremium(isEqualTo: true)
    .get();
```

### 🚀 Getting Started

#### Installation
```yaml
dependencies:
  firestore_odm: ^1.0.0
  
dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.0
```

#### Basic Usage
1. Define your models with `@CollectionPath` annotation
2. Run `dart run build_runner build` to generate ODM code
3. Use the generated ODM classes for type-safe Firestore operations

### 🔮 Future Plans

#### Planned Features
- **Subcollection Support**: Enhanced support for Firestore subcollections
- **Transaction Support**: Type-safe transaction operations
- **Batch Operations**: Efficient batch write operations
- **Offline Support**: Enhanced offline capabilities
- **Migration Tools**: Database migration and schema evolution tools

#### Performance Improvements
- **Query Optimization**: Further optimization of generated queries
- **Bundle Size**: Continued reduction of generated code size
- **Build Performance**: Faster code generation for large projects

### 🙏 Acknowledgments

This project was built with inspiration from:
- **Mongoose**: MongoDB ODM that pioneered many of these patterns
- **Prisma**: Modern database toolkit with excellent type safety
- **Freezed**: Immutable data classes for Dart
- **Cloud Firestore**: Google's NoSQL document database

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This is the initial release. Future versions will maintain backward compatibility while adding new features and improvements.