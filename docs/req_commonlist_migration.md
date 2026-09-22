# CommonListComponent — Migration Requirement

## §1 Purpose

`CommonListComponent` is the central page container for both the **bid list** and the **shared list** (offer list) views. It fetches, paginates, and renders a virtual-scrolled list of vehicle inventory items; manages multi-select and bulk-remove for bid-list vehicles; orchestrates shared-list sender/offer-list filtering; and coordinates analytics, translations, and feature-flag gates across all of these workflows. The component is dual-mode: at mount time it reads `BidListStateService.isSharedList` and branches all subsequent behaviour accordingly.

---

## §2 State and Props

### Inputs
No `@Input()` properties. All configuration is read from DI services and NgXs store at mount time.

### Outputs
| Output | Type | When emitted |
|---|---|---|
| `selectAllSharedListVehiclesToggled` | `EventEmitter<boolean>` | After the shared-list select-all checkbox changes state |
| `selectAllBidListVehiclesToggled` | `EventEmitter<boolean>` | After the bid-list select-all checkbox changes state |

### Key internal state (maps to React `useState` / refs)
| Field | Type | React equivalent |
|---|---|---|
| `isSharedList` | `boolean` | Context / prop from `ServiceContextProvider` |
| `page` / `scrollPosition` | `number` | `useRef` or URL param |
| `currentView` | `'CARD' \| 'LIST'` | `useState` (persistent via query / store) |
| `isMobile` | `boolean` | `useState` updated on resize |
| `mobileFilters` | `boolean` | `useState` |
| `removedUuids` | `BehaviorSubject<string[]>` | `useRef` + `useState` |
| `bidList$` | `Observable<{items, pagination}>` | Return value of `usePaginatedBidList()` |
| `loaderShells` | `any[]` | Derived from pagination.itemsPerPage |
| `userUuid` / `offerListName` | `string` | `useState` |
| `sharedList` / `offerLists` | `any[]` | `useState` |
| `sharedListSelectAll` / `bidListSelectAll` / `vehicleSelectAll` | `boolean` | `useState` (or from toggle service hook) |
| `bidListMultiSelectEnabled` | `boolean` | `useState` |
| `financeSources` / `dealershipCollection` | arrays | `useState` |
| `translatedObject` / `bidlistTranslations` / `bidlistInventoryItemTranslations` | objects | Populated by `useTranslation()` |
| `multiOfferActionSuccess` / `multiOfferActionErrors` | banners | `useState` |
| `bidListMultiRemoveSuccess` / `bidListMultiRemoveError` | banners | `useState` |

---

## §3 Dependencies (DI → React hooks)

| Angular token | React hook | Purpose |
|---|---|---|
| `Store` (NgXs) | `useVehicleToggleStore()`, `useBidListToggleStore()`, `useSharedListToggleStore()`, `useConfigurationStore()`, `useVDPConfigStore()` | Global state — must be ported to Zustand stores or React Context |
| `AnalyticsService` | `useAnalytics()` | Page load + event tracking |
| `InventoryService` | `useInventory()` | mark/unmark reviewed |
| `BidListFilterService` | `useBidListFilter()` | Filter-change subscription |
| `ConfigurationService` | `useConfiguration()` | Current time + component config |
| `OrganizationService` | `useOrganization()` | Org profiles per dealer |
| `PaginatedBidListService` | `usePaginatedBidList()` | Core data stream — items + pagination state |
| `FinanceSourceService` | `useFinanceSources()` | Finance source lists |
| `TranslocoService` | `useTranslation()` | i18n key maps |
| `BidListStateService` | `ServiceContext` | isSharedList, hasRemovableBidListItem |
| `VehiclesService` | `useVehicles()` | isLeadBuyer, islegacyBidlistLinkEnabled |
| `VehiclePageService` | `useVehiclePage()` | refresh trigger + scroll/page config |
| `OfferListService` | `useOfferList()` | Sender list for shared-by dropdown |
| `ActivatedRoute` + `Router` | `useSearchParams()` + `useNavigate()` | Query params read + clear |
| `SharedListToggleService` | `useSharedListToggle()` | Shared-list multi-select |
| `BidListToggleService` | `useBidListToggle()` | Bid-list multi-select (50-item cap) |
| `SharedListStateService` | `ServiceContext` extension | hasDealerAndListNameSpecified, hasItemPendingAction |
| `LaunchDarklyService` | `useFlag(key, default)` | 10 feature flags (see §7) |
| `BidListService` | `useBidListApi()` | Multi-remove API |
| `DateUtilsService` | `useDateUtils()` | Date formatting |
| `CommonListTypeService` | `useCommonListType()` | List type code + list name for analytics |
| `MeasuredSizeVirtualScrollStrategy` | `useMeasuredVirtualScroll()` | Virtual scroll strategy |
| `ModalLauncherService` | `useModalLauncher()` | Imperative modal outlet registration |

---

## §4 Key Workflows

1. **Mount (bid-list mode)**: Read `isSharedList = false` from context → `setupPagination()` → `bidList$` observable wired → render virtual-scroll list.
2. **Mount (shared-list mode)**: `isSharedList = true` → `getSenderList()` → populates shared-by + offer-list dropdowns → `setupPagination()`.
3. **Deep-link init**: Query params `sharedBy` + `offerListUuid` pre-select sender on init; cleared from URL once processed.
4. **Pagination**: `changePage(n)` → `paginatedBidList.goToPage(n)` → scroll to top → reset select-all. `changePerPage(n)` → `setPerPage(n)` → dispatch `SetBidItemsPerPage` → reset vehicles.
5. **Virtual scroll**: `setupPagination` taps item stream to call `virtualScrollStrategy.setItemKeys()`. View toggle to CARD triggers `contentRendered` wait before focusing heading.
6. **View toggle**: `toggleView('LIST' | 'CARD')` → `persistView()` → NgXs `PersistLastBidListView` → focus heading element.
7. **Collapse rows**: `toggleCollapseState(collapsed)` → invalidate heights → dispatch `SetBidListDefaultCollapsed` → scroll to top.
8. **Individual remove / undo**: `remove(uuid)` adds to `removedUuids` BehaviorSubject (pessimistically hides item); `undo(uuid)` splices it out. The observable pipeline subtracts `removedUuids.length` from `pagination.totalItems`.
9. **Bid-list multi-remove**: Toggle multi-select mode → user checks vehicles (capped at 50) → `bidListMultiRemoveSubmit('REMOVE')` → show ActionSubmittingModal → API call → success/error banners → `remove()` each non-failed uuid → close modal.
10. **Shared-list multi-action**: Check shared-list vehicles → `showMultiActionModal(action)` → SharedListMultiActionModal → on result `createBanners()` → translate + render banners.
11. **Refresh**: `VehiclePageService.refreshBidList$` subscription triggers `refreshBidList()` at any time.
12. **Finance sources**: Fetched per-dealership lazily as `OrganizationService.getOrganization()` resolves; merged into `financeSources` array deduplicated by `financeSourceUuid`.
13. **Analytics**: `analyticsTrackPageLoad()` fires ~500ms after init with section/subsection from `CommonListTypeService`.
14. **Translations**: `getTranslations()` issues a single `selectTranslateObject` with 5 root keys and maps the result into `bidlistInventoryItemTranslations` + `bidlistTranslations` flat objects passed to child components.

---

## §5 Lifecycle

| Hook | What it does |
|---|---|
| `constructor` | Sets `window` ref; calls `setValuesFromQueryParams()`; subscribes `bidListFilterService.getBidListFilter()` for pagination triggers; subscribes `vehiclePageService.sharedPageConfig` for scroll/page restore |
| `ngOnInit` | `populateDealerships()`, `checkForPersistentView()`, `detectIfMobile()`, `isSharedList` from context, `isCustomOffer`, `getTranslations()`, `initializeBidList()`, `subscribeToVehiclePageService()`, `userProfile` snapshot, finance-source fetch (non-lead-buyer), store subscriptions for tenant name, lead-buyer dealerships, configuration, vehicle toggles, select-all synchronisation |
| `ngAfterViewInit` | Registers `modalOutlet.viewContainerRef` with `ModalLauncherService` |
| `ngOnDestroy` | Dispatches `UpdateSharedListSelectAll(false)`, `UpdateBidListSelectAll(false)`, `UpdateVehicleSelectAll(false)`; completes `destroyed$`; calls `paginatedBidList.disconnect()` |

React equivalent: single `useEffect(() => { /* all init */ ; return () => { /* cleanup */ }; }, [])`.

---

## §6 Child Components (template dependencies)

All are Angular components — each is a migration blocker until ported:

| Angular component | Selector | Notes |
|---|---|---|
| `BidlistActionBarComponent` | `<app-bidlist-action-bar>` | Already in bidlist-remote (run-01) |
| `SharedListActionBarComponent` | `<app-shared-list-action-bar>` | **Not yet migrated** |
| `BidlistFiltersComponent` | `<app-bidlist-filters>` | Already in bidlist-remote (run-01) |
| `BidlistInventoryItemComponent` | `<app-bidlist-inventory-item>` | Already in bidlist-remote (run-01) |
| `ListRowInventoryItemComponent` | `<app-list-row-inventory-item>` | **Not yet migrated** |
| `SharedListMultiActionModalComponent` | `<app-shared-list-multi-action-modal>` | **Not yet migrated** |
| `ActionSubmittingModalComponent` | from `remarketing-ui-components-lib` | **Not yet migrated** |
| `PaginationComponent` | from `remarketing-ui-components-lib` | **Not yet migrated** |
| `ErrorModalComponent` | from `@ally/remarketing/shared/ui` | **Not yet migrated** |
| `CommonBannerComponent` | from `remarketing-ui-components-lib` | **Not yet migrated** |
| `ErrorMessageComponent` | from `remarketing-ui-components-lib` | **Not yet migrated** |
| `DropdownSelectComponent` | from `remarketing-ui-components-lib` | **Not yet migrated** |
| `SwVehicleContainerHookComponent` | `<app-sw-vehicle-container-hook>` | **Not yet migrated** |
| `BidlistSortSelectComponent` | `<app-bidlist-sort-select>` | Already in bidlist-remote (run-01) |
| `CdkVirtualScrollViewport` | from `@angular/cdk/scrolling` | Replace with react-virtual or native |
| `VirtualItemMeasureDirective` | `[virtualItemMeasure]` | Custom virtual scroll strategy — needs React port |
| `ModalPortalDirective` | from `@ally/remarketing/shared/ui` | Replace with React portal |
| `TrapFocusComponent` | from `remarketing-ui-components-lib` | Replace with focus-trap-react or equivalent |

---

## §7 React Migration Notes

### §7a Architecture recommendation

Do NOT try to port `CommonListComponent` as a single React component. Recommended decomposition:

1. **`useCommonList()`** — master hook; owns: pagination stream, dual-mode branching, sender list, remove/undo queue, select-all logic, feature flags
2. **`useCommonListTranslations()`** — translates all key maps; returns flat translation objects
3. **`useCommonListMultiRemove()`** — multi-remove submit, success/error banners, action-modal coordination
4. **`useCommonListMultiAction()`** — shared-list multi-action modal coordination and offer-action banners
5. **`CommonList.tsx`** — JSX only; delegates all logic to the hooks above; renders child components via props

Global NgXs state (`VehicleToggleState`, `BidListToggleState`, `SharedListToggleState`, `VDPConfigurationState`) must be migrated to Zustand stores before this component can be functional. Until that work is done, these will remain `MIGRATION_TODO(state)` blocked items.

### §7b Hook Extraction Recommendation

| Hook | Methods to extract |
|---|---|
| `useCommonList` | `initializeBidList`, `setupPagination`, `connectPaginatedBidList`, `refreshBidList`, `refreshTime`, `detectIfMobile`, `setValuesFromQueryParams`, `clearQueryParamValues`, `setVehicleCheckboxPage`, `setListView`, `setHasDealerAndListNameSpecified`, `subscribeToVehiclePageService`, `updateVehicleListCount`, `isVehicleListsSame`, `setScrollPosition`, `checkForPersistentView`, `persistView`, `toggleView`, `toggleCollapseState`, `setHasPendingAction`, `setHasRemovableBidListItem`, `trackById`, `showMobileFilters`, `hideMobileFilters` |
| `useCommonListTranslations` | `getTranslations`, `updateNotAvailableTranslation` |
| `useCommonListMultiRemove` | `bidListMultiRemoveSubmit`, `setBidListMultiRemoveSuccessBanner`, `setBidListMultiRemoveErrorBanners`, `closeBidListMultiRemoveSuccess`, `closeBidListMultiRemoveError`, `toggleBidListMultiSelect`, `selectAllBidListVehiclesToggle`, `handleSelectAllBidListVehiclesClick`, `filterSelectedBidItems`, `filterSelectedBidItemsVehicles`, `getRemovableAuctionItemUuidsForItems`, `isRemovableBidListItem`, `hasBeenRemoved` |
| `useCommonListMultiAction` | `showMultiActionModal`, `setSelectedFinanceSourcesForModal`, `createBanners`, `setMultiActionBanner`, `clearMultiActionBanners`, `closeSuccessBanner`, `closeErrorBanner`, `getSenderList`, `setInitialOfferListState`, `sharedBySelection`, `listNameSelection`, `resetSelectedVehicles`, `handleSelectAllSharedListVehiclesClick`, `setSelectAllSharedListVehicles`, `setSelectAllBidListVehicles`, `setVehicleToggleSubscricptions`, `toggleSelectAllVehicleToggle`, `evaluateSelectAllCheckbox`, `getAuctionItemUuidsForItemsPendingBuyerAction`, `isSharedListVehicleToggled`, `isVehicleToggled`, `isBidListVehicleToggled` |
| Component-level only | `remove`, `undo`, `review`, `navigateTo`, `redirectToLegacyBidlist`, `fetchFinanceSource`, `fetchOrgProfiles`, `populateDealerships`, `analyticsTrackPageLoad`, `analyticsVehiclesRemoved`, `analyticsMessageReference`, `focusListViewHeading`, `focusTableViewHeading`, `alignCtaBtns` |

---

## §8 Behavioral Invariants

1. `removedUuids` length is subtracted from `pagination.totalItems` — display count must match visible items before a full refresh.
2. `virtualScrollStrategy.invalidateHeights()` must run **before** `SetBidListDefaultCollapsed` is dispatched — order is load-bearing.
3. Bid-list select-all is capped at 50 items total (already-toggled + newly added ≤ 50).
4. `ngOnDestroy` (React: `useEffect` cleanup) must reset all three global toggle `selectAll` states to false.
5. `ModalLauncherService.registerOutlet` must run after the DOM renders (React equivalent: `useEffect` with a `useRef` to the portal container).

---

## §9 Open Questions / Risks

- **NgXs global state**: `VehicleToggleState`, `BidListToggleState`, `SharedListToggleState`, `VDPConfigurationState`, `ConfigurationState`, `OfferListState`, `LastBidListViewState` are all unported NgXs slices. This component cannot be functionally complete until all are replaced by Zustand or equivalent React stores. These will be MIGRATION_TODO(state) blocked items.
- **CDK Virtual Scroll + MeasuredSizeVirtualScrollStrategy**: The custom `MeasuredSizeVirtualScrollStrategy` measures item heights and provides a mean estimate for unrendered items. This has no direct React equivalent and needs a custom implementation or replacement with `react-virtual` / `@tanstack/virtual`.
- **ModalPortalDirective**: Angular portal; replace with `ReactDOM.createPortal`.
- **remarketing-ui-components-lib components** (Pagination, DropdownSelect, ErrorMessage, CommonBanner, ActionSubmittingModal, TrapFocus): These are Angular-only; all are MIGRATION_TODO(childComponent) blocked items.
- **`@Inject('window')` token**: Replace with `window` global directly in React (no DI needed).
- **`ChangeDetectorRef.markForCheck()`**: Remove entirely — React re-renders on state change automatically.

---

## §10 Domain Rules / Edge Cases

1. `isRemovableBidListItem` — 7 statuses prevent removal (see §4 source). Non-removable items are excluded from multi-select.
2. When `sharedByUuid` deep-link fails to find the sender, `setBackToAllSenders()` resets the dropdown and shows an "not available" error modal.
3. Failed multi-remove items with no VIN are silently skipped in error banner generation (stale browser window scenario).
4. `bidListFilterService.getBidListFilter()` subscription in constructor (not `ngOnInit`) means filter changes re-trigger pagination even if the component is re-parented.
5. `SHARED_LIST_DEFAULT_ITEMS_PER_PAGE = 50` overrides any user preference when in shared-list mode.

---

## §11 Migration Complexity Assessment

**Complexity: HIGH** — this component is a page-level container that assembles almost the entire bid list feature.

Key risks in order of severity:
1. **NgXs global state** — 6+ unported state slices; no React equivalent exists yet. All multi-select, pagination-config, and view-persistence logic is blocked.
2. **Child components** — 8+ Angular-only child components render as `MIGRATION_TODO(childComponent)` blocked items.
3. **CDK Virtual Scroll** — custom strategy class with height measurement; requires custom React hook or library swap.
4. **Translation volume** — `bidlistInventoryItemTranslations` has ~30 keys assembled from 5 translation root keys; exact key paths must be preserved.

**Recommended migration order for sub-features:**
1. Port NgXs toggle/config slices to Zustand first.
2. Port remaining child components (SharedListActionBar, ListRowInventoryItem, Pagination, modals).
3. Port CommonListComponent last, once all its dependencies are green.
