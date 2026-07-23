/// CrewAI-benzeri yerel multi-agent primitifleri.
/// Harici LLM / API key kullanılmaz.
library;

enum ProcessType { sequential, hierarchical }

class AgentTask {
  const AgentTask({
    required this.id,
    required this.description,
    required this.expectedOutput,
    required this.agentRole,
    this.contextKeys = const [],
  });

  final String id;
  final String description;
  final String expectedOutput;
  final String agentRole;
  final List<String> contextKeys;
}

class AgentOutput {
  const AgentOutput({
    required this.agentRole,
    required this.taskId,
    required this.payload,
    this.summary = '',
  });

  final String agentRole;
  final String taskId;
  final Map<String, dynamic> payload;
  final String summary;
}

class CrewContext {
  CrewContext([Map<String, AgentOutput>? seed]) : _outputs = {...?seed};

  final Map<String, AgentOutput> _outputs;

  void put(AgentOutput output) => _outputs[output.agentRole] = output;

  AgentOutput? operator [](String role) => _outputs[role];

  Map<String, dynamic> snapshot() {
    return {
      for (final entry in _outputs.entries)
        entry.key: {
          'summary': entry.value.summary,
          'payload': entry.value.payload,
        },
    };
  }
}

abstract class Agent {
  String get role;
  String get goal;
  String get backstory;

  AgentOutput execute(AgentTask task, CrewContext context);
}

class CrewResult {
  const CrewResult({
    required this.outputs,
    required this.finalPayload,
  });

  final List<AgentOutput> outputs;
  final Map<String, dynamic> finalPayload;
}

class Crew {
  Crew({
    required this.agents,
    required this.tasks,
    this.process = ProcessType.sequential,
  });

  final List<Agent> agents;
  final List<AgentTask> tasks;
  final ProcessType process;

  CrewResult kickoff({Map<String, dynamic> inputs = const {}}) {
    final context = CrewContext();
    context.put(
      AgentOutput(
        agentRole: 'inputs',
        taskId: 'bootstrap',
        payload: inputs,
        summary: 'Oyuncu ve oyun durumu',
      ),
    );

    final outputs = <AgentOutput>[];

    if (process == ProcessType.sequential) {
      for (final task in tasks) {
        final agent = _agentFor(task.agentRole);
        final output = agent.execute(task, context);
        context.put(output);
        outputs.add(output);
      }
    } else {
      // hierarchical: manager (ilk agent) görevleri dağıtır — aynı sırayı kullanır
      for (final task in tasks) {
        final agent = _agentFor(task.agentRole);
        final output = agent.execute(task, context);
        context.put(output);
        outputs.add(output);
      }
    }

    final last = outputs.isEmpty ? <String, dynamic>{} : outputs.last.payload;
    return CrewResult(outputs: outputs, finalPayload: last);
  }

  Agent _agentFor(String role) {
    return agents.firstWhere(
      (a) => a.role == role,
      orElse: () => throw StateError('Agent bulunamadı: $role'),
    );
  }
}
