

class SyntaxError extends Error {
    final String message;
    SyntaxError(this.message);
    String toString() => "Syntax error: $message";
}