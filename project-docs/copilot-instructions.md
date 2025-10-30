# Jardulli Bot Buddy - AI Coding Agent Instructions

## Project Overview
This is a chat-based AI assistant application for Jardulli Máquinas built with Vite, React, TypeScript, shadcn/ui, and Supabase. The app enables authenticated users to have AI-powered conversations with a knowledge base, provide feedback, and share responses.

## Architecture & Data Flow

### Core Components
- **`src/pages/Index.tsx`**: Main chat interface managing conversation state, messages, and real-time updates
- **`src/components/ChatSidebar.tsx`**: Sidebar for conversation navigation and management
- **`src/components/MessageActions.tsx`**: Action buttons (copy, feedback, share) attached to AI responses
- **`src/pages/Auth.tsx`**: Authentication page with sign-up/sign-in tabs

### Data Flow
1. User authenticates → Supabase Auth creates profile (via `handle_new_user()` trigger)
2. User creates conversation → `conversations` table entry → `messages` inserted with real-time subscription
3. AI response simulated in `Index.tsx` (replace with actual AI integration)
4. Negative feedback → stored in `message_feedback` → triggers WhatsApp Edge Function

### Supabase Integration
- **Client**: `src/integrations/supabase/client.ts` - configured with localStorage persistence
- **Database**: Uses Row Level Security (RLS) - users only access their own data
- **Tables**: `profiles`, `conversations`, `messages`, `message_feedback`
- **Realtime**: Messages use Supabase realtime (`ALTER PUBLICATION supabase_realtime`) for live updates
- **Edge Function**: `supabase/functions/send-whatsapp-feedback/index.ts` sends negative feedback to WhatsApp

## Development Workflows

### Commands
- **Dev**: `npm run dev` (starts Vite on port 8080)
- **Build**: `npm run build` (production) or `npm run build:dev` (development mode)
- **Lint**: `npm i` (ESLint with flat config in `eslint.config.js`)
- **Preview**: `npm run preview`

### Environment Variables
Required in `.env`:
- `VITE_SUPABASE_URL`: Supabase project URL
- `VITE_SUPABASE_PUBLISHABLE_KEY`: Supabase anon/public key

### Adding shadcn/ui Components
Use the configured alias structure from `components.json`:
```bash
npx shadcn@latest add [component-name]
```
Components auto-install to `src/components/ui/` with proper path aliases.

## Project-Specific Conventions

### Styling
- **Theme System**: Uses `next-themes` with light/dark mode (controlled via `ThemeToggle.tsx`)
- **CSS Variables**: All colors defined in `src/index.css` using HSL format with CSS custom properties
- **Utility Function**: Use `cn()` from `src/lib/utils.ts` to merge Tailwind classes with shadcn variants

### TypeScript Patterns
- **Database Types**: Auto-generated in `src/integrations/supabase/types.ts` (regenerate on schema changes)
- **Import Aliases**: `@/` resolves to `src/` (configured in `vite.config.ts` and `tsconfig.json`)
- **Component Props**: Explicitly typed interfaces (e.g., `ChatSidebarProps`, `MessageActionsProps`)

### State Management
- **React Query**: Used via `@tanstack/react-query` for server state (initialized in `App.tsx`)
- **Local State**: `useState` for UI state, conversation/message data fetched from Supabase
- **Auth State**: Managed through `supabase.auth.onAuthStateChange()` listeners

### UI Patterns
- **Toast Notifications**: Use `useToast()` hook from `src/hooks/use-toast.ts` for user feedback
- **Dialog Patterns**: shadcn Dialog component for modals (see negative feedback in `MessageActions.tsx`)
- **Loading States**: Show `Loader2` icons from `lucide-react` during async operations

## Integration Points

### Supabase Realtime
Messages subscribe to INSERT events in `Index.tsx`:
```typescript
supabase.channel("messages").on("postgres_changes", {...})
```
Unsubscribe on unmount to prevent memory leaks.

### WhatsApp Feedback Flow
Negative feedback triggers Edge Function that formats message for WhatsApp Web API (phone: 5519982121616).

### AI Integration Placeholder
Located in `Index.tsx` `handleSendMessage()` - currently simulated with `setTimeout()`. Replace with actual AI/LLM integration calling your knowledge base.

## Key Files Reference
- **Routing**: `src/App.tsx` (React Router with catch-all for 404)
- **Database Schema**: `supabase/migrations/20251005150233_*.sql`
- **Tailwind Config**: `tailwind.config.ts` (extended with custom sidebar colors)
- **Component Library**: `src/components/ui/` (shadcn/ui components)

## Notes
- Project generated via Lovable.dev - changes pushed to repo are reflected in Lovable
- Uses Bun lockfile (`bun.lockb`) but npm commands work fine
- Portuguese UI/UX language (Brazilian Portuguese)
