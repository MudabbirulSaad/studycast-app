import 'package:studycast/application/job_service.dart';
import 'package:studycast/application/project_service.dart';
import 'package:studycast/application/script_service.dart';
import 'package:studycast/domain/api/studycast_models.dart';

typedef GeneratePodcastProgress = void Function(GeneratePodcastEvent event);
typedef WorkflowDelay = Future<void> Function(Duration duration);

class GeneratePodcastWorkflow {
  const GeneratePodcastWorkflow({
    required ProjectService projectService,
    required ScriptService scriptService,
    required JobService jobService,
    Duration pollInterval = const Duration(seconds: 2),
    WorkflowDelay delay = Future<void>.delayed,
  }) : this._(projectService, scriptService, jobService, pollInterval, delay);

  const GeneratePodcastWorkflow._(
    this._projectService,
    this._scriptService,
    this._jobService,
    this._pollInterval,
    this._delay,
  );

  final ProjectService _projectService;
  final ScriptService _scriptService;
  final JobService _jobService;
  final Duration _pollInterval;
  final WorkflowDelay _delay;

  Future<GeneratePodcastResult> generateFromPastedScript(
    GeneratePodcastRequest request, {
    GeneratePodcastProgress? onEvent,
  }) async {
    final project = await _projectService.createProject(request.projectTitle);
    onEvent?.call(
      GeneratePodcastEvent(
        type: GeneratePodcastEventType.projectCreated,
        project: project,
      ),
    );

    final script = await _scriptService.savePastedScript(
      projectId: project.id,
      text: request.scriptText,
    );
    onEvent?.call(
      GeneratePodcastEvent(
        type: GeneratePodcastEventType.scriptSaved,
        project: project,
        script: script,
      ),
    );

    final submittedJob = await _jobService.submitJob(
      projectId: project.id,
      options: request.jobOptions,
    );
    onEvent?.call(
      GeneratePodcastEvent(
        type: GeneratePodcastEventType.jobSubmitted,
        project: project,
        script: script,
        job: submittedJob,
      ),
    );

    final finalJob = await _waitForTerminalJob(
      submittedJob,
      project,
      script,
      onEvent,
    );
    final outcome = GeneratePodcastOutcome.fromJobStatus(finalJob.status);
    onEvent?.call(
      GeneratePodcastEvent(
        type: _eventTypeForOutcome(outcome),
        project: project,
        script: script,
        job: finalJob,
      ),
    );

    return GeneratePodcastResult(
      project: project,
      script: script,
      finalJob: finalJob,
      outcome: outcome,
      audioReady: outcome == GeneratePodcastOutcome.completed,
      failureReason: outcome == GeneratePodcastOutcome.completed
          ? null
          : finalJob.failureReason ?? finalJob.message,
    );
  }

  Future<Job> _waitForTerminalJob(
    Job submittedJob,
    ProjectSummary project,
    Script script,
    GeneratePodcastProgress? onEvent,
  ) async {
    var currentJob = submittedJob;
    while (!currentJob.status.isTerminal) {
      await _delay(_pollInterval);
      currentJob = await _jobService.getJob(currentJob.id);
      onEvent?.call(
        GeneratePodcastEvent(
          type: GeneratePodcastEventType.jobPolled,
          project: project,
          script: script,
          job: currentJob,
        ),
      );
    }
    return currentJob;
  }

  GeneratePodcastEventType _eventTypeForOutcome(
    GeneratePodcastOutcome outcome,
  ) {
    return switch (outcome) {
      GeneratePodcastOutcome.completed => GeneratePodcastEventType.completed,
      GeneratePodcastOutcome.failed => GeneratePodcastEventType.failed,
      GeneratePodcastOutcome.cancelled => GeneratePodcastEventType.cancelled,
      GeneratePodcastOutcome.interrupted =>
        GeneratePodcastEventType.interrupted,
    };
  }
}

class GeneratePodcastRequest {
  const GeneratePodcastRequest({
    required this.projectTitle,
    required this.scriptText,
    this.jobOptions,
  });

  final String projectTitle;
  final String scriptText;
  final StartJobOptions? jobOptions;
}

class GeneratePodcastResult {
  const GeneratePodcastResult({
    required this.project,
    required this.script,
    required this.finalJob,
    required this.outcome,
    required this.audioReady,
    required this.failureReason,
  });

  final ProjectSummary project;
  final Script script;
  final Job finalJob;
  final GeneratePodcastOutcome outcome;
  final bool audioReady;
  final String? failureReason;
}

enum GeneratePodcastOutcome {
  completed,
  failed,
  cancelled,
  interrupted;

  static GeneratePodcastOutcome fromJobStatus(JobStatus status) {
    return switch (status) {
      JobStatus.completed => GeneratePodcastOutcome.completed,
      JobStatus.failed => GeneratePodcastOutcome.failed,
      JobStatus.cancelled => GeneratePodcastOutcome.cancelled,
      JobStatus.interrupted => GeneratePodcastOutcome.interrupted,
      _ => throw StateError('Job status is not terminal: ${status.toJson()}'),
    };
  }
}

class GeneratePodcastEvent {
  const GeneratePodcastEvent({
    required this.type,
    this.project,
    this.script,
    this.job,
  });

  final GeneratePodcastEventType type;
  final ProjectSummary? project;
  final Script? script;
  final Job? job;
}

enum GeneratePodcastEventType {
  projectCreated,
  scriptSaved,
  jobSubmitted,
  jobPolled,
  completed,
  failed,
  cancelled,
  interrupted,
}

extension on JobStatus {
  bool get isTerminal {
    return switch (this) {
      JobStatus.completed ||
      JobStatus.failed ||
      JobStatus.cancelled ||
      JobStatus.interrupted => true,
      JobStatus.queued ||
      JobStatus.running ||
      JobStatus.cancelRequested => false,
    };
  }
}
