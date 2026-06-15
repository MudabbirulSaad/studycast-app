# API Reference

Source: `http://127.0.0.1:8000/openapi.json`
API: Study Podcast Generator API `0.1.0`
Server: `/` on the current host

This file documents the backend contract the Android app will implement against. Regenerate it whenever the OpenAPI JSON changes.

## Tags

- `projects`: Project workspace metadata and summaries.
- `scripts`: Active study script save and retrieval.
- `jobs`: Generation job submission, inspection, and control.
- `queue`: Generation queue summary.
- `audio`: Generated WAV audio downloads and streams.
- `settings`: Runtime settings and engine reload controls.
- `voices`: Voice profiles and uploaded voice samples.

## Android Notes

- Project and job IDs are app-generated UUID strings.
- Date-time fields are ISO 8601 strings.
- Audio endpoints return `audio/wav` bytes and support HTTP byte ranges through the optional `Range` header.
- Standard API errors use `ErrorResponse`; validation errors use `HTTPValidationError`.
- The built-in voice profile ID is `default`.

## Endpoint Index

| Method | Path | Operation | Tags |
| --- | --- | --- | --- |
| `POST` | `/api/v1/projects` | `projects_create` | `projects` |
| `GET` | `/api/v1/projects` | `projects_list` | `projects` |
| `GET` | `/api/v1/projects/{project_id}` | `projects_get` | `projects` |
| `PUT` | `/api/v1/projects/{project_id}/script` | `scripts_save` | `scripts` |
| `GET` | `/api/v1/projects/{project_id}/script` | `scripts_get` | `scripts` |
| `POST` | `/api/v1/projects/{project_id}/jobs` | `jobs_submit` | `jobs` |
| `GET` | `/api/v1/jobs` | `jobs_list` | `jobs` |
| `GET` | `/api/v1/jobs/{job_id}` | `jobs_get` | `jobs` |
| `POST` | `/api/v1/jobs/{job_id}/cancel` | `jobs_cancel` | `jobs` |
| `POST` | `/api/v1/jobs/{job_id}/rerun` | `jobs_rerun` | `jobs` |
| `GET` | `/api/v1/jobs/{job_id}/script` | `jobs_get_script` | `jobs` |
| `GET` | `/api/v1/queue` | `queue_summary` | `queue` |
| `GET` | `/api/v1/projects/{project_id}/audio/final` | `audio_download_project_final` | `audio` |
| `GET` | `/api/v1/projects/{project_id}/audio/stream` | `audio_stream_project_final` | `audio` |
| `GET` | `/api/v1/jobs/{job_id}/audio/final` | `audio_download_job_final` | `audio` |
| `GET` | `/api/v1/jobs/{job_id}/audio/stream` | `audio_stream_job_final` | `audio` |
| `GET` | `/api/v1/settings` | `settings_get` | `settings` |
| `PUT` | `/api/v1/settings` | `settings_update` | `settings` |
| `POST` | `/api/v1/settings/reload` | `settings_reload` | `settings` |
| `GET` | `/api/v1/settings/runtime-status` | `settings_runtime_status` | `settings` |
| `GET` | `/api/v1/settings/tts-engines` | `settings_get_tts_engines` | `settings` |
| `PUT` | `/api/v1/settings/tts-engine` | `settings_update_tts_engine` | `settings` |
| `GET` | `/api/v1/voices` | `voices_list` | `voices` |
| `POST` | `/api/v1/voices` | `voices_upload` | `voices` |

## Endpoints

### POST /api/v1/projects

Summary: Create Project

Operation ID: `projects_create`

Tags: `projects`

Parameters: none

Request body: `application/json` `CreateProjectRequest` required

Responses: `201` `ProjectResponse`; `400` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: empty project title returns `domain_error`.

### GET /api/v1/projects

Summary: List Projects

Operation ID: `projects_list`

Tags: `projects`

Parameters: `q` query string optional

Request body: none

Responses: `200` array of `ProjectResponse`; `422` `HTTPValidationError`

### GET /api/v1/projects/{project_id}

Summary: Get Project

Operation ID: `projects_get`

Tags: `projects`

Parameters: `project_id` path UUID required

Request body: none

Responses: `200` `ProjectDetailResponse`; `404` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: missing project returns `not_found`.

### PUT /api/v1/projects/{project_id}/script

Summary: Save Script

Operation ID: `scripts_save`

Tags: `scripts`

Parameters: `project_id` path UUID required

Request body:

- `application/json` `SaveScriptRequest` required
- `multipart/form-data` required with `file` binary plain text upload

Multipart notes: uploaded scripts must be UTF-8 plain text. Runtime accepts `.txt` files with `text/plain` or `application/octet-stream`.

Responses: `200` `ScriptResponse`; `400` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: empty script text, missing project, non-text upload, or upload exceeding `max_script_size_bytes` return `domain_error`.

### GET /api/v1/projects/{project_id}/script

Summary: Get Script

Operation ID: `scripts_get`

Tags: `scripts`

Parameters: `project_id` path UUID required

Request body: none

Responses: `200` `ScriptResponse`; `404` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: project with no active script returns `not_found`.

### POST /api/v1/projects/{project_id}/jobs

Summary: Submit Job

Operation ID: `jobs_submit`

Tags: `jobs`

Parameters: `project_id` path UUID required

Request body: `application/json` `StartJobRequest` optional

Responses: `202` `JobResponse`; `400` `ErrorResponse`; `409` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: missing script or active job limit reached return `domain_error`; an existing active project job returns `active_job_exists`.

### GET /api/v1/jobs

Summary: List Jobs

Operation ID: `jobs_list`

Tags: `jobs`

Parameters:

- `status` query string optional. Comma-separated accepted values: `queued`, `running`, `cancel_requested`, `cancelled`, `failed`, `interrupted`, `completed`.
- `project_id` query string optional. Exact string filter; runtime does not validate UUID syntax for this query.
- `q` query string optional.

Request body: none

Responses: `200` array of `JobResponse`; `422` `HTTPValidationError`

### GET /api/v1/jobs/{job_id}

Summary: Get Job

Operation ID: `jobs_get`

Tags: `jobs`

Parameters: `job_id` path UUID required

Request body: none

Responses: `200` `JobResponse`; `404` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: missing job returns `not_found`.

### POST /api/v1/jobs/{job_id}/cancel

Summary: Cancel Job

Operation ID: `jobs_cancel`

Tags: `jobs`

Parameters: `job_id` path UUID required

Request body: none

Responses: `200` `JobResponse`; `400` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: missing job or terminal job cancellation returns `domain_error`.

### POST /api/v1/jobs/{job_id}/rerun

Summary: Rerun Job

Operation ID: `jobs_rerun`

Tags: `jobs`

Parameters: `job_id` path UUID required

Request body: none

Responses: `202` `JobResponse`; `400` `ErrorResponse`; `404` `ErrorResponse`; `409` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: active limit reached returns `domain_error`; missing job snapshot returns `not_found`; existing active project job returns `active_job_exists`.

### GET /api/v1/jobs/{job_id}/script

Summary: Get Job Script

Operation ID: `jobs_get_script`

Tags: `jobs`

Parameters: `job_id` path UUID required

Request body: none

Responses: `200` `ScriptResponse`; `404` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: missing job snapshot returns `not_found`.

### GET /api/v1/queue

Summary: Queue Summary

Operation ID: `queue_summary`

Tags: `queue`

Parameters: none

Request body: none

Responses: `200` `QueueResponse`

### GET /api/v1/projects/{project_id}/audio/final

Summary: Download Final Audio

Description: Download the latest completed WAV for the project. This serves the same bytes as the stream endpoint, but includes a stable download filename.

Operation ID: `audio_download_project_final`

Tags: `audio`

Parameters: `project_id` path UUID required; `Range` header string optional, for example `bytes=0-1023`

Request body: none

Responses: `200` `audio/wav` binary; `206` partial `audio/wav` binary; `400` text/plain malformed range; `416` range not satisfiable; `404` `ErrorResponse`; `422` `HTTPValidationError`

Response headers: `Accept-Ranges`, `Content-Length`, and for partial/unsatisfied ranges `Content-Range`.

Known errors: missing final WAV returns `not_found`.

### GET /api/v1/projects/{project_id}/audio/stream

Summary: Stream Final Audio

Description: Stream the latest completed WAV for the project. This serves the same bytes as the final endpoint without a download filename and supports byte-range requests.

Operation ID: `audio_stream_project_final`

Tags: `audio`

Parameters: `project_id` path UUID required; `Range` header string optional, for example `bytes=0-1023`

Request body: none

Responses: `200` `audio/wav` binary; `206` partial `audio/wav` binary; `400` text/plain malformed range; `416` range not satisfiable; `404` `ErrorResponse`; `422` `HTTPValidationError`

Response headers: `Accept-Ranges`, `Content-Length`, and for partial/unsatisfied ranges `Content-Range`.

Known errors: missing final WAV returns `not_found`.

### GET /api/v1/jobs/{job_id}/audio/final

Summary: Download Job Audio

Description: Download the completed WAV for this exact job. This serves the same bytes as the job stream endpoint, but includes a job-specific download filename.

Operation ID: `audio_download_job_final`

Tags: `audio`

Parameters: `job_id` path UUID required; `Range` header string optional, for example `bytes=0-1023`

Request body: none

Responses: `200` `audio/wav` binary; `206` partial `audio/wav` binary; `400` text/plain malformed range; `416` range not satisfiable; `404` `ErrorResponse`; `422` `HTTPValidationError`

Response headers: `Accept-Ranges`, `Content-Length`, and for partial/unsatisfied ranges `Content-Range`.

Known errors: missing final WAV returns `not_found`.

### GET /api/v1/jobs/{job_id}/audio/stream

Summary: Stream Job Audio

Description: Stream the completed WAV for this exact job. This serves the same bytes as the job final endpoint without a download filename and supports byte-range requests.

Operation ID: `audio_stream_job_final`

Tags: `audio`

Parameters: `job_id` path UUID required; `Range` header string optional, for example `bytes=0-1023`

Request body: none

Responses: `200` `audio/wav` binary; `206` partial `audio/wav` binary; `400` text/plain malformed range; `416` range not satisfiable; `404` `ErrorResponse`; `422` `HTTPValidationError`

Response headers: `Accept-Ranges`, `Content-Length`, and for partial/unsatisfied ranges `Content-Range`.

Known errors: missing final WAV returns `not_found`.

### GET /api/v1/settings

Summary: Get Runtime Settings

Operation ID: `settings_get`

Tags: `settings`

Parameters: none

Request body: none

Responses: `200` `RuntimeSettingsResponse`

### PUT /api/v1/settings

Summary: Update Runtime Settings

Operation ID: `settings_update`

Tags: `settings`

Parameters: none

Request body: `application/json` `UpdateRuntimeSettingsRequest` required

Responses: `200` `RuntimeSettingsResponse`; `400` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: non-editable setting or unavailable TTS engine returns `domain_error`.

### POST /api/v1/settings/reload

Summary: Reload Runtime Settings

Operation ID: `settings_reload`

Tags: `settings`

Parameters: none

Request body: none

Responses: `202` `RuntimeStatusResponse`; `400` `ErrorResponse`

Known errors: active jobs block reload; engine reload failure returns `domain_error`.

### GET /api/v1/settings/runtime-status

Summary: Get Runtime Status

Operation ID: `settings_runtime_status`

Tags: `settings`

Parameters: none

Request body: none

Responses: `200` `RuntimeStatusResponse`

### GET /api/v1/settings/tts-engines

Summary: Get Tts Engines

Operation ID: `settings_get_tts_engines`

Tags: `settings`

Parameters: none

Request body: none

Responses: `200` `TtsEngineSettingsResponse`

### PUT /api/v1/settings/tts-engine

Summary: Update Tts Engine

Operation ID: `settings_update_tts_engine`

Tags: `settings`

Parameters: none

Request body: `application/json` `UpdateTtsEngineRequest` required

Responses: `200` `TtsEngineSettingsResponse`; `400` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: non-editable setting or unavailable TTS engine returns `domain_error`.

### GET /api/v1/voices

Summary: List Voices

Operation ID: `voices_list`

Tags: `voices`

Parameters: none

Request body: none

Responses: `200` array of `VoiceProfileResponse`

### POST /api/v1/voices

Summary: Upload Voice

Operation ID: `voices_upload`

Tags: `voices`

Parameters: none

Request body: `multipart/form-data` required with `display_name` string and `file` binary voice sample upload

Multipart notes: display name must be non-empty after trimming whitespace. Runtime accepts filenames ending in `.wav`, `.mp3`, `.flac`, or `.m4a`; MIME type is not validated and no upload size limit is currently enforced here.

Responses: `201` `VoiceProfileResponse`; `400` `ErrorResponse`; `422` `HTTPValidationError`

Known errors: empty display name or unsupported voice sample extension returns `domain_error`.

## Shared Models

### ChunkResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `index` | `integer` | yes | min 0 |
| `speaker` | `string` | yes | - |
| `text` | `string` | yes | - |

### CreateProjectRequest

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `title` | `string` | yes | minLength 1 |

### ErrorResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `code` | `string` | yes | - |
| `message` | `string` | yes | - |
| `details` | `object | null` | yes | - |

### HTTPValidationError

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `detail` | `array<ValidationError>` | no | - |

### JobPhase

Type: `string`

Values: `queued`, `chunking`, `synthesizing`, `merging`, `finalizing`, `completed`

### JobResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `string (uuid)` | yes | App-generated job UUID string. |
| `project_id` | `string (uuid)` | yes | App-generated project UUID string. |
| `status` | `JobStatus` | yes | - |
| `phase` | `JobPhase` | yes | - |
| `progress_percent` | `integer` | yes | min 0, max 100 |
| `total_chunks` | `integer` | yes | min 0 |
| `completed_chunks` | `integer` | yes | min 0 |
| `current_chunk_index` | `integer | null` | yes | min 0 when present |
| `current_chunk_preview` | `string | null` | yes | maxLength 120 when present |
| `message` | `string` | yes | - |
| `failure_reason` | `string | null` | yes | - |
| `cancellation_requested` | `boolean` | yes | - |
| `created_at` | `string (date-time)` | yes | - |
| `started_at` | `string (date-time) | null` | yes | - |
| `updated_at` | `string (date-time)` | yes | - |
| `completed_at` | `string (date-time) | null` | yes | - |
| `snapshot` | `JobSnapshotResponse | null` | yes | - |

### JobSnapshotResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `job_id` | `string (uuid)` | yes | App-generated job UUID string. |
| `project_id` | `string (uuid)` | yes | App-generated project UUID string. |
| `script_text` | `string` | yes | - |
| `script_source` | `ScriptSource` | yes | - |
| `speakers` | `array<string>` | yes | - |
| `chunks` | `array<ChunkResponse>` | yes | - |
| `voice_profile_id` | `string` | yes | Built-in default voice uses `default`. |
| `tts_params` | `object<string, number>` | yes | Engine-specific numeric TTS parameters. |
| `created_at` | `string (date-time)` | yes | - |

### JobStatus

Type: `string`

Values: `queued`, `running`, `cancel_requested`, `cancelled`, `failed`, `interrupted`, `completed`

### ProjectDetailResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `string (uuid)` | yes | App-generated project UUID string. |
| `title` | `string` | yes | - |
| `created_at` | `string (date-time)` | yes | - |
| `updated_at` | `string (date-time)` | yes | - |
| `has_active_script` | `boolean` | yes | - |
| `latest_jobs` | `array<JobResponse>` | yes | - |

### ProjectResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `string (uuid)` | yes | App-generated project UUID string. |
| `title` | `string` | yes | - |
| `created_at` | `string (date-time)` | yes | - |
| `updated_at` | `string (date-time)` | yes | - |

### QueueResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `pending_count` | `integer` | yes | min 0 |
| `running_count` | `integer` | yes | min 0 |
| `completed_count` | `integer` | yes | min 0 |
| `max_active_jobs_total` | `integer` | yes | min 1 |
| `concurrency_limits` | `object<string, integer>` | yes | values min 0 |
| `queue_positions` | `object<string, integer>` | yes | values min 0 |

### RuntimeSettingsResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `values` | `RuntimeSettingsValuesResponse` | yes | - |
| `editable_fields` | `array<string>` | yes | - |
| `available_engines` | `array<string>` | yes | - |
| `reload_required` | `boolean` | yes | - |
| `runtime_status` | `string` | yes | one of `idle`, `reload_pending`, `reloading`, `ready`, `failed` |
| `last_reload_error` | `string | null` | yes | - |

### RuntimeSettingsValuesResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `active_tts_engine` | `string` | yes | - |
| `chatterbox_device` | `string` | yes | - |
| `max_script_size_bytes` | `integer` | yes | - |
| `max_chunk_chars` | `integer` | yes | - |
| `max_chunks` | `integer` | yes | - |
| `chatterbox_max_concurrent_jobs` | `integer` | yes | - |
| `audio_merge_max_concurrent_jobs` | `integer` | yes | - |
| `max_active_jobs_total` | `integer` | yes | - |
| `storage_root` | `string` | yes | - |
| `frontend_origin` | `string` | yes | - |
| `serve_frontend` | `boolean` | yes | - |

### RuntimeStatusResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `status` | `string` | yes | one of `idle`, `reload_pending`, `reloading`, `ready`, `failed` |
| `active_engine` | `string` | yes | - |
| `reload_required` | `boolean` | yes | - |
| `last_reload_error` | `string | null` | yes | - |

### ScriptResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `project_id` | `string (uuid)` | yes | App-generated project UUID string. |
| `text` | `string` | yes | - |
| `source` | `ScriptSource` | yes | - |
| `speakers` | `array<string>` | yes | - |
| `updated_at` | `string (date-time)` | yes | - |
| `chunks` | `array<ChunkResponse>` | yes | - |

### ScriptSource

Type: `string`

Values: `pasted`, `uploaded`

### StartJobRequest

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `voice_profile_id` | `string` | no | default `default`; built-in default voice uses `default` |
| `tts_params` | `object<string, number>` | no | Engine-specific numeric TTS parameters passed through to the active engine. Unknown keys are not validated by the API. |

Example:

```json
{
  "voice_profile_id": "default",
  "tts_params": {
    "cfg_weight": 0.7,
    "temperature": 0.4
  }
}
```

### TtsEngineSettingsResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `active_engine` | `string` | yes | - |
| `available_engines` | `array<string>` | yes | - |

### UpdateRuntimeSettingsRequest

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `values` | `object<string, string | integer | boolean>` | yes | Keys must be editable settings. |

Example:

```json
{
  "values": {
    "active_tts_engine": "fake",
    "max_chunk_chars": 320,
    "serve_frontend": false
  }
}
```

### UpdateTtsEngineRequest

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `engine` | `string` | yes | - |

### ValidationError

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `loc` | `array<string | integer>` | yes | Location |
| `msg` | `string` | yes | Message |
| `type` | `string` | yes | Error type |
| `input` | `any` | no | - |
| `ctx` | `object` | no | - |

### VoiceProfileResponse

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `string` | yes | Voice profile identifier. The built-in default voice uses `default`. |
| `display_name` | `string` | yes | - |
| `source` | `string` | yes | - |
| `sample_path` | `string | null` | yes | Deprecated legacy local storage path for the uploaded sample. Clients should use `has_sample` instead. |
| `has_sample` | `boolean` | yes | - |
| `created_at` | `string (date-time)` | yes | - |
| `updated_at` | `string (date-time)` | yes | - |

### SaveScriptRequest

Type: `object`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `text` | `string` | yes | minLength 1 |
| `source` | `ScriptSource` | no | default `pasted` |
