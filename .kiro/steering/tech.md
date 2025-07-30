# Technology Stack

## Backend
- **Language**: Kotlin 1.9.25
- **Runtime**: Java 21
- **Framework**: Spring Boot 3.5.3
- **Database**: PostgreSQL 17.5 (production), H2 (development/testing)
- **ORM**: Spring Data JPA with QueryDSL 5.0.0
- **Security**: Spring Security with JWT (jjwt 0.11.2)
- **Testing**: Kotest 5.4.2, SpringMockK 4.0.2, REST Assured 5.3.0
- **Build**: Gradle with Kotlin DSL

## Frontend
- **Language**: TypeScript
- **Framework**: Next.js with App Router
- **UI Library**: React
- **Styling**: Tailwind CSS
- **Components**: shadcn/ui
- **Font**: Hamlet
- **Package Manager**: PNPM with workspaces
- **Database Types**: Kysely
- **Linting**: ESLint

## Common Commands

### Backend
```bash
# Build the application
./gradlew build

# Run tests
./gradlew test

# Run the application
./gradlew bootRun
```

### Frontend
```bash
# Install dependencies
pnpm install

# Run development server
pnpm dev

# Build for production
pnpm build

# Run tests
pnpm test

# Lint code
pnpm lint
```

## Development Environment
- Use PostgreSQL 17.5 for production database queries and schema design
- H2 in-memory database for testing
- JWT tokens for stateless authentication
- QueryDSL for type-safe dynamic queries