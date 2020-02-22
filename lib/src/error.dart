

class SyntaxError extends Error {
    final String message;
    SyntaxError(this.message);
    String toString() => "Syntax error: $message";
}

class ReferenceError extends Error {
    final String message;
    ReferenceError(this.message);
    String toString() => "Reference error: $message";
}