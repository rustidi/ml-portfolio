---
name: streaming-chunk-boundary
description: How to split a streaming signal (audio/ASR, video/HLS, telemetry) into chunks for parallel processing without cutting through the middle of a meaningful unit. Covers VAD-aware chunking, force-cut safety nets, gapless recorder rotation, and backend ordering invariants.
triggers: ["chunk boundary", "streaming audio split", "ASR chunking", "VAD chunking", "gapless rotation"]
---

# Streaming Chunk Boundary

**When to load this skill:** you're splitting streaming audio (ASR / any transcription pipeline) into chunks for parallel processing. OR splitting streaming video (HLS), media, or telemetry into time-windows. OR designing any system where a chunk boundary can land in the middle of a meaningful unit (a word, a frame, a transaction).

## Core principle

**Hard fixed boundaries (`if elapsed >= 30s → cut`) are an anti-pattern for speech and seamless streams.** A word can be split in half, the transcript of the next chunk starts mid-word, and the downstream ML model loses context.

**The right pattern:** VAD-aware (Voice-Activity-Detection) chunking — cut only during pauses. For media, cut on silence / scene-cut / low-entropy window. For transactions, cut on a commit boundary, never in the middle of a batch.

## VAD-aware audio chunking (canonical pattern)

```swift
enum ChunkState {
    case recording(elapsedSec: Double)
    case waitingForSilence(elapsedSec: Double)  // passed target, waiting for a pause
    case rotating
}

// Tunable constants
let TARGET_CHUNK_SEC: Double      = 30.0     // target duration
let MAX_CHUNK_SEC: Double         = 45.0     // hard cap, force-cut if no silence
let SILENCE_RMS_THRESHOLD_DB: Float = -45.0  // RMS below this = silence
let SILENCE_MIN_DURATION_MS: Int  = 300      // X ms of continuous silence to trigger a cut

// Decision logic per audio frame (called every ~50ms)
func evaluateBoundary(elapsed: Double, currentRMSdb: Float, silenceAccumulatedMs: Int) -> Action {
    switch state {
    case .recording(let elapsed) where elapsed >= TARGET_CHUNK_SEC:
        state = .waitingForSilence(elapsedSec: elapsed)
        return .continue
    case .waitingForSilence(let elapsed):
        if elapsed >= MAX_CHUNK_SEC {
            return .forceCut(forceCut: true)         // 45s reached, no silence — overlap safety net
        }
        if currentRMSdb < SILENCE_RMS_THRESHOLD_DB && silenceAccumulatedMs >= SILENCE_MIN_DURATION_MS {
            return .cut(forceCut: false)             // clean cut in a pause
        }
        return .continue
    default:
        return .continue
    }
}
```

### Tunable thresholds (starting points)

| Parameter | Speech (long-form) | Speech (casual) | Music streaming |
|----------|--------------------------|--------------------------|-----------------|
| TARGET_CHUNK_SEC | 30 | 20-30 | 10 |
| MAX_CHUNK_SEC | 45 | 35 | 15 |
| SILENCE_RMS_DB | -45 | -50 | n/a (scene-cut) |
| SILENCE_MIN_MS | 300 (inter-word) | 250 | n/a |

**Test empirically:** run the pipeline over a gold-standard 30-min recording and measure the % of chunks that were force-cut. Target: <5%. Higher than that — increase `MAX_CHUNK_SEC` or decrease the `SILENCE_RMS` threshold.

## Force-cut safety net (when silence never comes)

Rare case: a long phrase with no pauses (e.g. an excited speaker, or an enumeration like "items 16, 17, 18, 19, 36, 37"). 45s reached with no silence → force-cut.

**Mitigation:** flag `forceCut=true` in the chunk metadata → the next chunk on the server is prepended with a 2s overlap window from the previous chunk:

```python
# Server-side (worker)
if chunk.force_cut:
    # Prepend last 2s of audio from chunk N-1 to chunk N before inference
    audio = concatenate([previous_chunk_tail_2s, current_chunk_audio])
    transcript = asr.transcribe(audio)
    # Drop the duplicated tail in the JSON output:
    transcript = drop_segments_overlapping(transcript, prev_chunk.transcript)
```

This safety net is **only** for force-cut chunks, not all of them (cost saving). If the cut happened in silence, no overlap is needed.

## Audio gap on rotate (double-recorder pattern)

Native `AVAudioRecorder.stop() + new AVAudioRecorder.record()` produces a 10-50ms gap (iOS audio-session reset). On sensitive speech this is audible as a clipped-word artifact.

**Pattern: double-recorder swap**

```swift
private var recorderA: AVAudioRecorder!  // currently recording
private var recorderB: AVAudioRecorder!  // prewarmed standby

func rotate() {
    // 1. Start B BEFORE stopping A (5ms overlap so we don't lose the last sample)
    let nextUrl = chunkUrl(for: nextIndex)
    recorderB = try makeRecorder(at: nextUrl)
    recorderB.record()

    // 2. Stop A after 5ms
    Task {
        try? await Task.sleep(nanoseconds: 5_000_000)
        recorderA.stop()
        swap(&recorderA, &recorderB)
        recorderB = nil  // released, re-instantiated on the next rotate
    }
}
```

**Target gap: <20ms.** Audio-sample loss is inaudible on 16kHz speech. If the double-recorder produces >20ms (verified empirically), fall back to a continuous `AVAudioEngine` + tap buffer split on the server.

## Prerequisite checklist before shipping this feature

- [ ] **Empirical gap measurement** on a real device (not the simulator). 10 test recordings × measure boundary gap_ms via FFT phase analysis. Target <20ms.
- [ ] **Force-cut rate** on a gold-standard recording <5%. Higher — adjust thresholds.
- [ ] **Silence false-positive rate** — the recorder must not cut on breathing or a background click. Test on a realistic recording.
- [ ] **Edge case: user paused while in the waiting-for-silence state** — the chunk stays open, resumes on unpause, force-cuts and closes on manual stop.
- [ ] **Re-listen to the audio** after chunking to confirm there are no glitches at the boundaries.

## Backend chunk ordering invariants

```sql
CREATE TABLE "RecordingChunk" (
  "recordingId" TEXT,
  "index"       INT,
  "objectKey"   TEXT,
  "forceCut"    BOOLEAN DEFAULT false,
  "startOffsetSec" FLOAT,
  "durationSec"    FLOAT,
  "sha256"      TEXT,
  -- ...
  UNIQUE("recordingId", "index")  -- critical: prevent duplicate chunks
);
```

**Invariants:**
1. `chunk[N].startOffsetSec == sum(chunk[0..N-1].durationSec)` — no gaps in the timeline
2. `expectedChunkCount` reported by the client on finalize `== COUNT(RecordingChunk WHERE status='done')` — wait until equality OR timeout (e.g. 90s)
3. All chunks of one recording share the **same tenant context** — enforce a multi-tenant boundary check at the chunk-ingest endpoint
4. **sha256 verify** on the server before enqueueing inference — chunk-integrity proof

## When this skill applies

- **Always:** building streaming transcription, or any ASR/STT pipeline with per-chunk processing
- **Adaptable:** streaming video segmentation (HLS), realtime telemetry windowing, large file uploads with resumability
- **NOT applicable:** batch single-file processing (whole-file inference for a post-finalize pass)

## The underlying insight

The right instinct is not an overlap window (the standard streaming approach), but a **silence-aware cut**. It elegantly closes the chunk-boundary-artifact concern without any overlap-merge logic on the server — reserving the overlap machinery for the rare force-cut case only.
