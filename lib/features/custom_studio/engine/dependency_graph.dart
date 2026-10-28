import 'formula_ast.dart';
import 'formula_parser.dart';

class CircularDependencyException implements Exception {
  const CircularDependencyException(this.cyclePath);
  final List<String> cyclePath;

  @override
  String toString() =>
      'CircularDependencyException: Cycle detected: ${cyclePath.join(" -> ")}';
}

class DependencyNode {
  DependencyNode(this.id, this.formula, this.ast);
  final String id;
  final String formula;
  final ExprNode ast;
  Set<String> get dependencies => ast.collectVariableReferences();
}

/// Analyzes dependencies across multiple calculated results and provides a safe topological evaluation order.
class DependencyGraph {
  DependencyGraph(this.nodes);

  final Map<String, DependencyNode> nodes; // outputId -> DependencyNode

  /// Constructs a graph from outputId -> formula string mapping.
  factory DependencyGraph.fromFormulas(Map<String, String> formulas) {
    final map = <String, DependencyNode>{};
    for (final entry in formulas.entries) {
      final ast = FormulaParser.parseFormula(entry.value);
      map[entry.key] = DependencyNode(entry.key, entry.value, ast);
    }
    return DependencyGraph(map);
  }

  /// Returns calculated output IDs in the exact order they must be evaluated.
  /// Throws [CircularDependencyException] if any circular reference exists.
  List<String> getEvaluationOrder() {
    final ordered = <String>[];
    final visited =
        <String, int>{}; // 0 = unvisited, 1 = visiting (in stack), 2 = visited

    for (final id in nodes.keys) {
      visited[id] = 0;
    }

    void dfs(String current, List<String> path) {
      visited[current] = 1; // visiting
      path.add(current);

      final node = nodes[current];
      if (node != null) {
        for (final dep in node.dependencies) {
          // If the dependency is another calculated output
          if (nodes.containsKey(dep)) {
            final state = visited[dep] ?? 0;
            if (state == 1) {
              // Cycle detected!
              final cycleStart = path.indexOf(dep);
              final cycle = [...path.sublist(cycleStart), dep];
              throw CircularDependencyException(cycle);
            } else if (state == 0) {
              dfs(dep, path);
            }
          }
        }
      }

      visited[current] = 2; // finished
      path.removeLast();
      ordered.add(current);
    }

    for (final id in nodes.keys) {
      if ((visited[id] ?? 0) == 0) {
        dfs(id, []);
      }
    }

    return ordered;
  }
}
