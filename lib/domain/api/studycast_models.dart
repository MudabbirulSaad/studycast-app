enum ScriptSource {
  pasted,
  uploaded;

  static ScriptSource fromJson(Object? value) {
    return ScriptSource.values.byName(value as String);
  }

  String toJson() => name;
}

enum JobStatus {
  queued,
  running,
  cancelRequested,
  cancelled,
  failed,
  interrupted,
  completed;

  static JobStatus fromJson(Object? value) {
    return switch (value as String) {
      'cancel_requested' => JobStatus.cancelRequested,
      _ => JobStatus.values.byName(value),
    };
  }

  String toJson() {
    return switch (this) {
      JobStatus.cancelRequested => 'cancel_requested',
      _ => name,
    };
  }
}

enum JobPhase {
  queued,
  chunking,
  synthesizing,
  merging,
  finalizing,
  completed;

  static JobPhase fromJson(Object? value) {
    return JobPhase.values.byName(value as String);
  }

  String toJson() => name;
}

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectSummary.fromJson(Map<String, Object?> json) {
    return ProjectSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ProjectDetail extends ProjectSummary {
  const ProjectDetail({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required this.hasActiveScript,
    required this.latestJobs,
  });

  final bool hasActiveScript;
  final List<Job> latestJobs;

  factory ProjectDetail.fromJson(Map<String, Object?> json) {
    return ProjectDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      hasActiveScript: json['has_active_script'] as bool,
      latestJobs: _list(json['latest_jobs'], Job.fromJson),
    );
  }
}

class Chunk {
  const Chunk({
    required this.index,
    required this.speaker,
    required this.text,
  });

  final int index;
  final String speaker;
  final String text;

  factory Chunk.fromJson(Map<String, Object?> json) {
    return Chunk(
      index: json['index'] as int,
      speaker: json['speaker'] as String,
      text: json['text'] as String,
    );
  }
}

class Script {
  const Script({
    required this.projectId,
    required this.text,
    required this.source,
    required this.speakers,
    required this.updatedAt,
    required this.chunks,
  });

  final String projectId;
  final String text;
  final ScriptSource source;
  final List<String> speakers;
  final DateTime updatedAt;
  final List<Chunk> chunks;

  factory Script.fromJson(Map<String, Object?> json) {
    return Script(
      projectId: json['project_id'] as String,
      text: json['text'] as String,
      source: ScriptSource.fromJson(json['source']),
      speakers: (json['speakers'] as List<Object?>).cast<String>(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      chunks: _list(json['chunks'], Chunk.fromJson),
    );
  }
}

class StartJobOptions {
  const StartJobOptions({
    this.voiceProfileId = 'default',
    this.ttsParams = const {},
  });

  final String voiceProfileId;
  final Map<String, num> ttsParams;

  Map<String, Object?> toJson() {
    return {
      'voice_profile_id': voiceProfileId,
      'tts_params': ttsParams,
    };
  }
}

class Job {
  const Job({
    required this.id,
    required this.projectId,
    required this.status,
    required this.phase,
    required this.progressPercent,
    required this.totalChunks,
    required this.completedChunks,
    required this.currentChunkIndex,
    required this.currentChunkPreview,
    required this.message,
    required this.failureReason,
    required this.cancellationRequested,
    required this.createdAt,
    required this.startedAt,
    required this.updatedAt,
    required this.completedAt,
    required this.snapshot,
  });

  final String id;
  final String projectId;
  final JobStatus status;
  final JobPhase phase;
  final int progressPercent;
  final int totalChunks;
  final int completedChunks;
  final int? currentChunkIndex;
  final String? currentChunkPreview;
  final String message;
  final String? failureReason;
  final bool cancellationRequested;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final JobSnapshot? snapshot;

  factory Job.fromJson(Map<String, Object?> json) {
    return Job(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      status: JobStatus.fromJson(json['status']),
      phase: JobPhase.fromJson(json['phase']),
      progressPercent: json['progress_percent'] as int,
      totalChunks: json['total_chunks'] as int,
      completedChunks: json['completed_chunks'] as int,
      currentChunkIndex: json['current_chunk_index'] as int?,
      currentChunkPreview: json['current_chunk_preview'] as String?,
      message: json['message'] as String,
      failureReason: json['failure_reason'] as String?,
      cancellationRequested: json['cancellation_requested'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: _dateTimeOrNull(json['started_at']),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: _dateTimeOrNull(json['completed_at']),
      snapshot: _objectOrNull(json['snapshot'], JobSnapshot.fromJson),
    );
  }
}

class JobSnapshot {
  const JobSnapshot({
    required this.jobId,
    required this.projectId,
    required this.scriptText,
    required this.scriptSource,
    required this.speakers,
    required this.chunks,
    required this.voiceProfileId,
    required this.ttsParams,
    required this.createdAt,
  });

  final String jobId;
  final String projectId;
  final String scriptText;
  final ScriptSource scriptSource;
  final List<String> speakers;
  final List<Chunk> chunks;
  final String voiceProfileId;
  final Map<String, num> ttsParams;
  final DateTime createdAt;

  factory JobSnapshot.fromJson(Map<String, Object?> json) {
    return JobSnapshot(
      jobId: json['job_id'] as String,
      projectId: json['project_id'] as String,
      scriptText: json['script_text'] as String,
      scriptSource: ScriptSource.fromJson(json['script_source']),
      speakers: (json['speakers'] as List<Object?>).cast<String>(),
      chunks: _list(json['chunks'], Chunk.fromJson),
      voiceProfileId: json['voice_profile_id'] as String,
      ttsParams: (json['tts_params'] as Map<String, Object?>).cast<String, num>(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class QueueSummary {
  const QueueSummary({
    required this.pendingCount,
    required this.runningCount,
    required this.completedCount,
    required this.maxActiveJobsTotal,
    required this.concurrencyLimits,
    required this.queuePositions,
  });

  final int pendingCount;
  final int runningCount;
  final int completedCount;
  final int maxActiveJobsTotal;
  final Map<String, int> concurrencyLimits;
  final Map<String, int> queuePositions;

  factory QueueSummary.fromJson(Map<String, Object?> json) {
    return QueueSummary(
      pendingCount: json['pending_count'] as int,
      runningCount: json['running_count'] as int,
      completedCount: json['completed_count'] as int,
      maxActiveJobsTotal: json['max_active_jobs_total'] as int,
      concurrencyLimits: (json['concurrency_limits'] as Map<String, Object?>)
          .map((key, value) => MapEntry(key, value as int)),
      queuePositions: (json['queue_positions'] as Map<String, Object?>)
          .map((key, value) => MapEntry(key, value as int)),
    );
  }
}

class AudioBytes {
  const AudioBytes({
    required this.bytes,
    required this.statusCode,
    required this.headers,
  });

  final List<int> bytes;
  final int statusCode;
  final Map<String, String> headers;
}

class RuntimeSettings {
  const RuntimeSettings({
    required this.values,
    required this.editableFields,
    required this.availableEngines,
    required this.reloadRequired,
    required this.runtimeStatus,
    required this.lastReloadError,
  });

  final RuntimeSettingsValues values;
  final List<String> editableFields;
  final List<String> availableEngines;
  final bool reloadRequired;
  final String runtimeStatus;
  final String? lastReloadError;

  factory RuntimeSettings.fromJson(Map<String, Object?> json) {
    return RuntimeSettings(
      values: RuntimeSettingsValues.fromJson(json['values'] as Map<String, Object?>),
      editableFields: (json['editable_fields'] as List<Object?>).cast<String>(),
      availableEngines: (json['available_engines'] as List<Object?>).cast<String>(),
      reloadRequired: json['reload_required'] as bool,
      runtimeStatus: json['runtime_status'] as String,
      lastReloadError: json['last_reload_error'] as String?,
    );
  }
}

class RuntimeSettingsValues {
  const RuntimeSettingsValues({
    required this.activeTtsEngine,
    required this.chatterboxDevice,
    required this.maxScriptSizeBytes,
    required this.maxChunkChars,
    required this.maxChunks,
    required this.chatterboxMaxConcurrentJobs,
    required this.audioMergeMaxConcurrentJobs,
    required this.maxActiveJobsTotal,
    required this.storageRoot,
    required this.frontendOrigin,
    required this.serveFrontend,
  });

  final String activeTtsEngine;
  final String chatterboxDevice;
  final int maxScriptSizeBytes;
  final int maxChunkChars;
  final int maxChunks;
  final int chatterboxMaxConcurrentJobs;
  final int audioMergeMaxConcurrentJobs;
  final int maxActiveJobsTotal;
  final String storageRoot;
  final String frontendOrigin;
  final bool serveFrontend;

  factory RuntimeSettingsValues.fromJson(Map<String, Object?> json) {
    return RuntimeSettingsValues(
      activeTtsEngine: json['active_tts_engine'] as String,
      chatterboxDevice: json['chatterbox_device'] as String,
      maxScriptSizeBytes: json['max_script_size_bytes'] as int,
      maxChunkChars: json['max_chunk_chars'] as int,
      maxChunks: json['max_chunks'] as int,
      chatterboxMaxConcurrentJobs: json['chatterbox_max_concurrent_jobs'] as int,
      audioMergeMaxConcurrentJobs: json['audio_merge_max_concurrent_jobs'] as int,
      maxActiveJobsTotal: json['max_active_jobs_total'] as int,
      storageRoot: json['storage_root'] as String,
      frontendOrigin: json['frontend_origin'] as String,
      serveFrontend: json['serve_frontend'] as bool,
    );
  }
}

class RuntimeStatus {
  const RuntimeStatus({
    required this.status,
    required this.activeEngine,
    required this.reloadRequired,
    required this.lastReloadError,
  });

  final String status;
  final String activeEngine;
  final bool reloadRequired;
  final String? lastReloadError;

  factory RuntimeStatus.fromJson(Map<String, Object?> json) {
    return RuntimeStatus(
      status: json['status'] as String,
      activeEngine: json['active_engine'] as String,
      reloadRequired: json['reload_required'] as bool,
      lastReloadError: json['last_reload_error'] as String?,
    );
  }
}

class TtsEngineSettings {
  const TtsEngineSettings({
    required this.activeEngine,
    required this.availableEngines,
  });

  final String activeEngine;
  final List<String> availableEngines;

  factory TtsEngineSettings.fromJson(Map<String, Object?> json) {
    return TtsEngineSettings(
      activeEngine: json['active_engine'] as String,
      availableEngines: (json['available_engines'] as List<Object?>).cast<String>(),
    );
  }
}

class VoiceProfile {
  const VoiceProfile({
    required this.id,
    required this.displayName,
    required this.source,
    required this.samplePath,
    required this.hasSample,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String source;
  final String? samplePath;
  final bool hasSample;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VoiceProfile.fromJson(Map<String, Object?> json) {
    return VoiceProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      source: json['source'] as String,
      samplePath: json['sample_path'] as String?,
      hasSample: json['has_sample'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

DateTime? _dateTimeOrNull(Object? value) {
  return value == null ? null : DateTime.parse(value as String);
}

T? _objectOrNull<T>(
  Object? value,
  T Function(Map<String, Object?> json) parse,
) {
  return value == null ? null : parse(value as Map<String, Object?>);
}

List<T> _list<T>(
  Object? value,
  T Function(Map<String, Object?> json) parse,
) {
  return (value as List<Object?>)
      .map((item) => parse(item as Map<String, Object?>))
      .toList(growable: false);
}
