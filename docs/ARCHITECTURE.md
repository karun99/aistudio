# Architecture

AI Studio is a video-generation workbench split into a Next.js front end and a
FastAPI production backend that drives the OpenMontage pipeline.

## Components

| Component | Path | Responsibility |
|---|---|---|
| Studio UI | `my-video-app/` | Next.js 16 app: prompt composer, storyboard, render queue, player |
| Backend API | `my-video-app/backend/app.py` | FastAPI server: job creation, status, artefact download |
| Orchestrator | `my-video-app/backend/orchestrator.py` | Sequences the render stages |
| Media | `my-video-app/backend/media.py` | Probe, transcode and package rendered assets |
| Model access | `my-video-app/backend/llm.py` | Prompt expansion and shot-list generation |
| Budget | `my-video-app/backend/budget.py` | Per-job token and compute ceilings |
| Moderation | `my-video-app/backend/moderator.py` | Screens prompts before a job is accepted |
| Store | `my-video-app/backend/store.py` | Job metadata and artefact index |
| Cognitive module | `my-video-app/lib/neurobot.ts` | Spike-tensor / control-loop simulation used by the validation suite |

## Request flow

1. The composer posts a prompt to the backend. `moderator.py` screens it and
   `budget.py` reserves an allowance before any model is called.
2. `llm.py` expands the prompt into a shot list; the job is written to the store
   and queued.
3. `orchestrator.py` runs the stages in order and `media.py` writes the rendered
   artefacts into the project directory.
4. The UI polls job status and plays the finished file.

## Trust boundaries

- Model and service credentials are read from `.env` on the server only.
- Uploaded and generated media stay inside the configured projects directory.
- Budget ceilings stop a single job from exhausting the account allowance.
- Moderation happens before the first model call, not after.

## Verification

```bash
cd my-video-app
node --test lib/__tests__/neurobot.test.ts
python -m compileall -q backend
```

CI runs both on every push and pull request.
