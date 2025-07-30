# Project Structure

## Repository Organization
This is a monorepo containing both backend (Spring Boot) and frontend (Next.js) applications.

## Backend Architecture (Layered)
Follow the 4-layer architecture pattern with unidirectional data flow:

```
Controller -> Service -> Repository -> Entity
```

### Layer Responsibilities
- **Controller**: Handle HTTP requests, validate input, return JSON responses
- **Service**: Implement business logic, manage transactions with @Transactional
- **Repository**: Data access using JpaRepository and QueryDSL for complex queries
- **Entity**: Domain models mapped to database tables with JPA annotations

## Frontend Structure (Monorepo)
```
apps/
├── admin/          # Admin web application
│   ├── app/        # Next.js App Router
│   ├── components/ # React components
│   ├── actions/    # Server actions
│   └── lib/        # Utilities
└── web/            # User web application
    ├── app/        # Next.js App Router
    ├── components/ # React components
    ├── contexts/   # React Context API
    ├── entities/   # Entity definitions
    ├── features/   # Feature modules
    ├── hooks/      # Custom React hooks
    ├── actions/    # Server actions
    └── lib/        # Utilities

packages/
├── db-types/       # Database schema types (Kysely)
├── eslint-config/  # Shared ESLint configuration
├── typescript-config/ # Shared TypeScript configuration
├── ui/             # Shared UI components (shadcn/ui)
└── web-api/        # API client types
```

## Naming Conventions
- Use Korean for documentation and user-facing content
- Use English for code, variable names, and technical comments
- Follow Spring Boot conventions for backend (PascalCase for classes, camelCase for methods)
- Follow React/Next.js conventions for frontend (PascalCase for components, camelCase for functions)

## Package Organization
- Group by feature/domain rather than technical layer when possible
- Keep related components, hooks, and utilities together
- Use shared packages for cross-application code
- Maintain clear separation between admin and user applications