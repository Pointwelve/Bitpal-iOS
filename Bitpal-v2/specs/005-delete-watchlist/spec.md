# Feature Specification: Delete Watchlist

**Feature Branch**: `005-delete-watchlist`
**Created**: 2025-11-28
**Status**: Draft
**Input**: User description: "delete watchlist"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Remove Individual Coin from Watchlist (Priority: P1)

A user wants to remove a specific cryptocurrency from their watchlist when they are no longer interested in tracking its price. This allows users to keep their watchlist focused and relevant to their current interests.

**Why this priority**: This is the core functionality - users need to be able to manage their watchlist by removing coins they no longer want to track. Without this, the watchlist becomes cluttered and less useful over time.

**Independent Test**: Can be fully tested by adding a coin to the watchlist, then removing it via long-press context menu, and verifying the coin no longer appears in the watchlist.

**Acceptance Scenarios**:

1. **Given** a user has a watchlist with multiple coins, **When** the user long-presses on a coin row, **Then** a context menu with delete option is revealed
2. **Given** a user sees the context menu on a coin row, **When** the user taps the "Delete" option, **Then** the coin is removed from the watchlist immediately
3. **Given** a user removes a coin from the watchlist, **When** the app is closed and reopened, **Then** the removed coin remains absent from the watchlist (deletion persists)

---

### User Story 2 - Cancel Delete Action (Priority: P2)

A user accidentally opens the context menu on a coin they want to keep. The system should provide a way to cancel the deletion.

**Why this priority**: Prevents accidental data loss and improves user confidence in the app. While not essential for core functionality, it significantly improves user experience.

**Independent Test**: Can be tested by opening the context menu, then dismissing it without selecting delete, and verifying the coin remains in the watchlist.

**Acceptance Scenarios**:

1. **Given** a user opens the context menu via long-press, **When** the user taps outside the menu, **Then** the menu is dismissed and the coin remains in the watchlist
2. **Given** a user opens the context menu, **When** the user taps elsewhere on the screen, **Then** the context menu is dismissed and the coin remains

---

### User Story 3 - Visual Feedback During Deletion (Priority: P3)

A user deletes a coin and expects smooth visual feedback confirming the action completed successfully.

**Why this priority**: Enhances perceived performance and user satisfaction. The app should feel responsive and polished.

**Independent Test**: Can be tested by deleting a coin and observing the animation behavior.

**Acceptance Scenarios**:

1. **Given** a user confirms deletion of a coin, **When** the deletion is processed, **Then** the coin row animates smoothly out of the list
2. **Given** a coin is being deleted, **When** the deletion animation plays, **Then** surrounding coins smoothly reposition to fill the gap

---

### Edge Cases

- What happens when the user tries to delete the last coin in the watchlist? The empty state should be displayed.
- What happens if deletion fails due to a storage error? A user-friendly error message should be shown, and the coin remains in the watchlist.
- What happens if the user rapidly swipes multiple rows? Each row handles its own delete state independently.
- What happens during app backgrounding mid-deletion? Deletion completes and persists.

### Phase Scope Validation

**Feature Category** (check one):
- [x] Watchlist feature (explicitly in Phase 1)
- [ ] Manual Portfolio feature (explicitly in Phase 1)
- [ ] OUT OF SCOPE - Requires constitution amendment and explicit approval

**Approval Required**: N/A - This feature is explicitly part of Phase 1 watchlist functionality as defined in CLAUDE.md ("Remove coins from watchlist (swipe to delete)").

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to remove individual coins from the watchlist via long-press context menu
- **FR-002**: System MUST persist coin removal so deleted coins do not reappear after app restart
- **FR-003**: System MUST reveal a context menu with delete option when user long-presses on a coin row
- **FR-004**: System MUST remove the coin from the watchlist when user taps the delete option
- **FR-005**: System MUST allow users to cancel by dismissing the context menu (tap outside)
- **FR-006**: System MUST provide smooth animation when a coin is removed from the list
- **FR-007**: System MUST update the watchlist display immediately after deletion (no refresh required)
- **FR-008**: System MUST handle the empty watchlist state when the last coin is deleted
- **FR-009**: System MUST preserve the deleted coin's data in the coin database (only remove the watchlist association)
- **FR-010**: System MUST use consistent delete UX with Transaction History (context menu pattern)

### Key Entities

- **WatchlistItem**: Represents the association between a user's watchlist and a specific coin. Contains coinId, dateAdded, and sortOrder. Deletion removes this entity.
- **Coin**: The cryptocurrency data itself. Not affected by watchlist deletion - only the WatchlistItem reference is removed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can remove a coin from their watchlist in under 2 seconds (swipe + tap)
- **SC-002**: Deletion animation completes within 300ms, maintaining 60fps throughout
- **SC-003**: 100% of deleted coins remain removed after app restart (data persistence verified)
- **SC-004**: Users can successfully cancel an accidental delete gesture 100% of the time before confirming
- **SC-005**: Empty watchlist state is displayed correctly when all coins are removed

## Assumptions

- The watchlist feature with add functionality already exists
- WatchlistItem Swift Data model is already implemented
- Long-press context menu pattern matches Transaction History for consistency
- No undo functionality is required for Phase 1 (can be added later)
- Deletion does not require confirmation dialog - context menu dismiss is sufficient to cancel
