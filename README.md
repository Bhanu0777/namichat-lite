# NamiChat Lite — Every Wave Connects

A production-ready, realtime mobile chat app built with Flutter + FastAPI.

## Tech Stack

| Layer   | Technology |
|---------|------------|
| Mobile  | Flutter 3.22+, Riverpod, GoRouter, Dio, Hive, Flutter Secure Storage, WebSocket |
| Backend | Python 3.12, FastAPI, PostgreSQL 16, SQLAlchemy 2.0, Alembic, JWT, WebSockets |
| Infra   | Docker, Docker Compose (Postgres + Redis + API) |
| Principles | Clean Architecture, feature-first folders, SOLID, Repository pattern |

## Architecture

```
┌─────────────────┐     HTTP REST / WebSocket     ┌──────────────────────┐
│  Flutter client │ ───────────────────────────▶  │   FastAPI service    │
│  (Clean Arch.)  │ ◀───────────────────────────  │  (Layered, modular)  │
└─────────────────┘                               └──────────┬───────────┘
                                                           │ SQLAlchemy
                                                   ┌───────▼────────┐
                                                   │  PostgreSQL     │
                                                   └────────────────┘
```

### Mobile (Clean Architecture, feature-first)

```
lib/
  app/                 # App shell: router, theme, screens
  core/                # Cross-cutting infrastructure
    constants/         # AppConstants (derives from Env)
    errors/            # Failure hierarchy (sealed classes)
    utils/             # Either, Env (compile-time dart-define config)
    network/           # DioClient + interceptors, WebSocketClient, ApiEndpoints
    storage/           # SecureStorage (keychain), LocalStorage (Hive), StorageKeys
    di/                # Riverpod provider graph (injection_container.dart)
  design_system/       # Flow UI — ocean-wave tokens + reusable widgets
  features/
    auth/              # Full clean-arch: login, register, token refresh, logout
    chat/              # User search; WebSocket chat (scaffold ready)
    profile/           # View + edit profile
  main.dart
```

### Backend (Layered, modular)

```
app/
  core/                # config (pydantic-settings), database, security (JWT), exceptions
  models/              # SQLAlchemy 2.x ORM models: User, Chat, ChatMember, Message, Group
  schemas/             # Pydantic DTOs: auth.py (user/token), message.py (chat/message/WS)
  repositories/        # BaseRepository, UserRepository, ChatRepository, MessageRepository
  services/            # AuthService, UserService, ChatService, MessageService
  routers/             # health, auth, users — composition via register_routers()
  websockets/          # ConnectionManager (UUID-keyed), chat_ws.py (WS endpoint)
  main.py              # FastAPI app, CORS, exception handlers
alembic/               # Migrations — 0001_initial creates all 5 tables
```

## Quick Start

### Backend (Docker — recommended)

```bash
# 1. Copy env file (edit JWT_SECRET_KEY before production!)
cp backend/.env.example backend/.env

# 2. Start Postgres + Redis + API
docker compose up --build

# API will be available at http://localhost:8000
# Interactive docs: http://localhost:8000/docs
```

### Backend (local venv)

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your local DATABASE_URL
alembic upgrade head
uvicorn app.main:app --reload --port 8000
```

### Mobile

```bash
cd mobile
flutter pub get
# Run on emulator / physical device
flutter run

# With custom API URL (e.g. production)
flutter run --dart-define=BASE_URL=https://api.example.com
```

## Environment Configuration

### Backend (`backend/.env`)

| Variable | Description | Default |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+psycopg://postgres:postgres@localhost:5432/namichat` |
| `JWT_SECRET_KEY` | **Change in production** | `change-me-in-production` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Access token TTL | `60` |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Refresh token TTL | `7` |
| `CORS_ORIGINS` | Comma-separated allowed origins | `*` |
| `REDIS_URL` | Redis for WS pub/sub (multi-instance) | `redis://localhost:6379/0` |

### Mobile (`--dart-define` at build time)

| Variable | Description | Default |
|---|---|---|
| `BASE_URL` | API base URL | `http://10.0.2.2:8000` (Android emulator) |
| `API_VERSION` | API version prefix | `/api/v1` |
| `APP_ENV` | `development` or `production` | `development` |
| `ENABLE_LOGGING` | Network request logging | `true` |

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | — | Health check |
| POST | `/api/v1/auth/register` | — | Register user |
| POST | `/api/v1/auth/login` | — | Login (returns JWT pair) |
| POST | `/api/v1/auth/refresh` | — | Rotate tokens |
| POST | `/api/v1/auth/logout` | — | Stateless logout |
| GET | `/api/v1/users/me` | ✓ | Get current user |
| PATCH | `/api/v1/users/me` | ✓ | Update profile |
| GET | `/api/v1/users/search?query=` | ✓ | Search users |
| GET | `/api/v1/users/{id}` | ✓ | Get user by ID |
| WS | `/ws/{chat_id}?token=` | ✓ | Realtime chat channel |

## WebSocket Protocol

Connect: `ws://host:8000/ws/{chat_id}?token=<access_token>`

Send:
```json
{ "content": "Hello!" }
```

Receive:
```json
{
  "event": "message",
  "chat_id": "<uuid>",
  "message": {
    "id": "<uuid>",
    "chat_id": "<uuid>",
    "sender_id": "<uuid>",
    "content": "Hello!",
    "is_read": false,
    "created_at": "2026-07-14T12:00:00Z"
  }
}
```

## Design System

`mobile/lib/design_system/` — ocean-wave themed Material 3 components:

```dart
import 'package:namichat_lite/design_system/flow.dart';

// FlowButton, FlowCard, FlowTextField, FlowLoadingIndicator,
// FlowEmptyState, FlowErrorState, FlowSkeleton, FlowColors,
// FlowSpacing, FlowTypography, FlowDialogs, FlowSnackbar, FlowTheme
```

## Adding a Feature

**Backend:**
1. Add model to `app/models/` and export in `app/models/__init__.py`
2. Add Pydantic schemas to `app/schemas/`
3. Create a repository in `app/repositories/`
4. Add business logic in `app/services/`
5. Create a router in `app/routers/<feature>.py` and register in `app/routers/__init__.py`
6. Generate a migration: `alembic revision --autogenerate -m "add <feature>"`

**Mobile:**
1. Create `features/<feature>/{data,domain,presentation}/` structure
2. Implement datasource → model → repository → use case → provider → page
3. Register providers in `core/di/injection_container.dart`
4. Register routes in `app/router/feature_routes.dart`

## Security Notes

- JWT tokens are stateless — logout clears client-side only (no server-side blocklist yet)
- `JWT_SECRET_KEY` **must** be changed before production deployment
- `CORS_ORIGINS` should be restricted to specific domains in production
- Rate limiting on auth endpoints is not yet implemented
