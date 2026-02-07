# General rules when working on a typescript

## Commands

- `npm run build`: Build the project
- `npm run typecheck`: Run the typechecker
- `npm run test`: Run tests (prefer single test files for speed)

## Code style

- Use ES modules (import/export), not CommonJS (require)
- Destructure imports when possible: `import { foo } from 'bar'`
- See `components/Button.tsx` for canonical component structure

## Workflow

- Always typecheck after making a series of code changes
- API routes go in `app/api/` following existing patterns
