# 아키텍처 개요

이 프로젝트는 PNPM 워크스페이스를 사용하는 모노레포 구조로 구성되어 여러 애플리케이션과 패키지를 효율적으로 관리합니다. TypeScript를 기본 언어로 사용하며, Next.js와 React를 활용하여 웹 애플리케이션을 구축합니다. UI는 Tailwind CSS와 shadcn/ui를 통해 스타일링 및 컴포넌트화를 구현합니다.

## 주요 기술 스택

- **언어**: TypeScript
- **모노레포 관리**: PNPM Workspaces
- **프레임워크**: Next.js (App Router)
- **UI 라이브러리**: React
- **스타일링**: Tailwind CSS
- **UI 컴포넌트**: shadcn/ui
- **린팅**: ESLint
- **데이터베이스 타입**: kysely

## 프로젝트 구조

```
.
├── apps/                     # 개별 애플리케이션
│   ├── admin/                # 관리자용 웹 애플리케이션
│   │   ├── app/              # Next.js App Router
│   │   ├── components/       # React 컴포넌트
│   │   ├── actions/          # 서버 액션
│   │   ├── lib/              # 유틸리티 및 라이브러리
│   │   └── ...
│   └── web/                  # 사용자용 웹 애플리케이션
│       ├── app/              # Next.js App Router
│       ├── components/       # React 컴포넌트
│       ├── contexts/         # React Context API
|       ├── entities/         # 엔티티 모음.
|       ├── features/         # features 모음.
│       ├── hooks/            # React Hooks
│       ├── actions/          # 서버 액션
│       ├── lib/              # 유틸리티 및 라이브러리
│       └── ...
├── packages/                 # 공유 패키지
│   ├── db-types/             # 데이터베이스 스키마 및 타입 정의
│   ├── eslint-config/        # 공유 ESLint 설정
│   ├── typescript-config/    # 공유 TypeScript 설정
│   ├── ui/                   # 공유 UI 컴포넌트 (shadcn/ui 기반)
│   └── web-api/              # 웹 API 클라이언트 또는 관련 유틸리티
├── script/                   # 프로젝트 관련 스크립트
│   └── copy-ui.ts            # UI 관련 스크립트 (예: shadcn/ui 컴포넌트 복사)
├── package.json              # 프로젝트 전체 의존성 및 스크립트
├── pnpm-lock.yaml            # PNPM 락 파일
├── pnpm-workspace.yaml       # PNPM 워크스페이스 정의
├── tsconfig.json             # 루트 TypeScript 설정
└── ...
```

## 애플리케이션 (`apps/`)

### `apps/admin`

관리자 기능을 제공하는 Next.js 애플리케이션입니다. 주요 디렉토리는 다음과 같습니다.

- `app/`: Next.js의 App Router를 사용하여 페이지 라우팅 및 레이아웃을 관리합니다.
- `components/`: 관리자 애플리케이션에서 사용되는 React 컴포넌트들이 위치합니다. `ui/` 하위 디렉토리는 shadcn/ui 컴포넌트를 포함할 수 있습니다.
- `actions/`: Next.js 서버 액션을 정의하여 서버 측 로직을 처리합니다.
- `lib/`: 데이터베이스 연결(`db.ts`), 유틸리티 함수(`utils.ts`) 등을 포함합니다.

### `apps/web`

일반 사용자를 위한 웹 애플리케이션입니다. 주요 폴더 구조와 상세 규칙은 [`apps/web/ARCHITECTURE.md`](apps/web/ARCHITECTURE.md)에서 확인할 수 있습니다.
이 문서에서는 전체 프로젝트 구조와 역할만 개괄적으로 안내하며, apps/web의 폴더별 상세 규칙 및 의존성 원칙 등은 하위 문서를 참고하세요.

## 공유 패키지 (`packages/`)

모노레포 내의 여러 애플리케이션에서 공통으로 사용되는 코드와 설정을 관리합니다.

- **`db-types`**: kysely에 맞는 데이터베이스 스키마 타입 파일입니다.
- **`eslint-config`**: 일관된 코드 스타일과 품질을 유지하기 위한 ESLint 설정을 공유합니다.
- **`typescript-config`**: 공통 TypeScript 컴파일러 옵션을 제공하여 설정 중복을 줄입니다.
- **`ui`**: `shadcn/ui`를 기반으로 하거나 커스텀으로 제작된 공유 UI 컴포넌트 라이브러리입니다.
- **`web-api`**: 백엔드 API의 타입입니다.

## 주요 아키텍처 패턴 및 특징

- **모노레포**: PNPM 워크스페이스를 사용하여 코드 공유 및 의존성 관리를 용이하게 합니다.
- **Next.js App Router**: 서버 컴포넌트, 서버 액션 등을 활용하여 최신 웹 개발 패턴을 따릅니다.
- **컴포넌트 기반 UI**: React와 shadcn/ui를 사용하여 재사용 가능하고 유지보수 용이한 UI를 구축합니다.
- **타입스크립트**: 정적 타입 검사를 통해 코드 안정성을 높이고 개발자 경험을 향상시킵니다.
- **Tailwind CSS**: 유틸리티 우선 CSS 프레임워크를 사용하여 빠르고 유연한 스타일링을 지원합니다.
- **모듈화**: 기능별, 역할별 디렉토리 구조를 통해 코드의 응집도를 높이고 결합도를 낮춥니다.

## 향후 고려 사항

- 상태 관리 라이브러리 (예: Zustand, Jotai) 도입 여부
- 테스팅 전략 (단위, 통합, E2E 테스트) 구체화
- CI/CD 파이프라인 구축

이 문서는 프로젝트의 현재 아키텍처에 대한 개요를 제공하며, 프로젝트가 발전함에 따라 업데이트될 수 있습니다.
