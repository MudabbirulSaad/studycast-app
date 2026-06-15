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
    GeneratePodcastCancellationToken? cancellationToken,
    GeneratePodcastProgress? onEvent,
  }) async {
    if (cancellationToken?.isCancellationRequested ?? false) {
      return _cancelBeforeJob(onEvent: onEvent);
    }

    final project = await _projectService.createProject(request.projectTitle);
    onEvent?.call(
      GeneratePodcastEvent(
        type: GeneratePodcastEventType.projectCreated,
        project: project,
      ),
    );
    if (cancellationToken?.isCancellationRequested ?? false) {
      return _cancelBeforeJob(project: project, onEvent: onEvent);
    }

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
    if (cancellationToken?.isCancellationRequested ?? false) {
      return _cancelBeforeJob(
        project: project,
        script: script,
        onEvent: onEvent,
      );
    }

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

    final finalJobResult = await _waitForTerminalJob(
      submittedJob,
      project,
      script,
      cancellationToken,
      onEvent,
    );
    final finalJob = finalJobResult.job;
    final outcome = finalJobResult.cancelledByRequest
        ? GeneratePodcastOutcome.cancelled
        : GeneratePodcastOutcome.fromJobStatus(finalJob.status);
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
      failureReason:
          outcome == GeneratePodcastOutcome.completed ||
              finalJobResult.cancelledByRequest
          ? null
          : finalJob.failureReason ?? finalJob.message,
    );
  }

  Future<_FinalJobResult> _waitForTerminalJob(
    Job submittedJob,
    ProjectSummary project,
    Script script,
    GeneratePodcastCancellationToken? cancellationToken,
    GeneratePodcastProgress? onEvent,
  ) async {
    var currentJob = submittedJob;
    while (!currentJob.status.isTerminal) {
      if (cancellationToken?.isCancellationRequested ?? false) {
        return _cancelBackendJob(currentJob, project, script, onEvent);
      }

      await _delay(_pollInterval);
      if (cancellationToken?.isCancellationRequested ?? false) {
        return _cancelBackendJob(currentJob, project, script, onEvent);
      }

      currentJob = await _jobService.getJob(currentJob.id);
      onEvent?.call(
        GeneratePodcastEvent(
          type: GeneratePodcastEventType.jobPolled,
          project: project,
          script: script,
          job: currentJob,
        ),
      );
      if (!currentJob.status.isTerminal &&
          (cancellationToken?.isCancellationRequested ?? false)) {
        return _cancelBackendJob(currentJob, project, script, onEvent);
      }
    }
    return _FinalJobResult(currentJob);
  }

  Future<_FinalJobResult> _cancelBackendJob(
    Job job,
    ProjectSummary project,
    Script script,
    GeneratePodcastProgress? onEvent,
  ) async {
    onEvent?.call(
      GeneratePodcastEvent(
        type: GeneratePodcastEventType.cancellationRequested,
        project: project,
        script: script,
        job: job,
      ),
    );

    final cancelledJob = await _jobService.cancelJob(job.id);
    return _FinalJobResult(cancelledJob, cancelledByRequest: true);
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

  GeneratePodcastResult _cancelBeforeJob({
    ProjectSummary? project,
    Script? script,
    GeneratePodcastProgress? onEvent,
  }) {
    onEvent?.call(
      GeneratePodcastEvent(
        type: GeneratePodcastEventType.cancellationRequested,
        project: project,
        script: script,
      ),
    );
    onEvent?.call(
      GeneratePodcastEvent(
        type: GeneratePodcastEventType.cancelled,
        project: project,
        script: script,
      ),
    );

    return GeneratePodcastResult(
      project: project,
      script: script,
      finalJob: null,
      outcome: GeneratePodcastOutcome.cancelled,
      audioReady: false,
      failureReason: null,
    );
  }
}

class _FinalJobResult {
  const _FinalJobResult(this.job, {this.cancelledByRequest = false});

  final Job job;
  final bool cancelledByRequest;
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

class GeneratePodcastCancellationToken {
  bool get isCancellationRequested => _isCancellationRequested;

  bool _isCancellationRequested = false;

  void cancel() {
    _isCancellationRequested = true;
  }
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

  final ProjectSummary? project;
  final Script? script;
  final Job? finalJob;
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
  cancellationRequested,
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
