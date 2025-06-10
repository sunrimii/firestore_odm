import 'filter_builder.dart';

/// Field builder for numeric operations
class NumericFieldBuilder<T extends num> {
  final String fieldPath;

  const NumericFieldBuilder(this.fieldPath);

  /// Set the field value
  UpdateOperation call(T value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }

  /// Increment the field value
  UpdateOperation increment(T value) {
    return UpdateOperation(fieldPath, UpdateOperationType.increment, value);
  }
}

/// Field builder for DateTime operations
class DateTimeFieldBuilder {
  final String fieldPath;

  const DateTimeFieldBuilder(this.fieldPath);

  /// Set the field value
  UpdateOperation call(DateTime value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }

  /// Set to server timestamp
  UpdateOperation serverTimestamp() {
    return UpdateOperation(
      fieldPath,
      UpdateOperationType.serverTimestamp,
      null,
    );
  }
}

/// Field builder for List operations
class ListFieldBuilder<T> {
  final String fieldPath;

  const ListFieldBuilder(this.fieldPath);

  /// Set the field value
  UpdateOperation call(List<T> value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }

  /// Add element to array
  UpdateOperation add(T element) {
    return UpdateOperation(fieldPath, UpdateOperationType.arrayAdd, element);
  }

  /// Remove element from array
  UpdateOperation remove(T element) {
    return UpdateOperation(fieldPath, UpdateOperationType.arrayRemove, element);
  }
}

/// Represents an order by field
class OrderByField {
  final String field;
  final bool descending;

  const OrderByField(this.field, {this.descending = false});
}
