# Current Project Situation - 2026-09-06

## Summary of Issues
1.  **User Role Misconfiguration:** New user registrations default to `CUSTOMER` regardless of selection. This is caused by hardcoded defaults in the frontend JS (`web-app/js/`) and enforced default values in the backend SQLAlchemy models (`api/app/models/models.py`).
2.  **Missing Truck-Customer Linking Logic:** While the database schema supports linking `Truck` to `Provider` and `Job` to `Truck`, the job creation flow in `api/app/api/v1/jobs.py` lacks the logic to automatically identify and assign a "free" truck (one without an active, unexpired `TruckLock`) to a customer job request.

## Planned Remediation

### Phase 1: Fix Registration Role Handling
- **Frontend:** Remove `'customer'` defaults in `web-app/js/app.js` and `web-app/js/helpers.js`. Update UI to mandate role selection.
- **Backend:** 
    - Remove `default=UserRole.CUSTOMER` from `api/app/models/models.py`.
    - Update `api/app/api/v1/auth.py` to enforce explicit role validation during registration.

### Phase 2: Implement Truck Linking Logic
- **Job Creation Flow:** Update `api/app/api/v1/jobs.py` within the `create_job` function:
    - Query `Trucks` matching user criteria (e.g., class/capacity).
    - Exclude `Trucks` that have an active entry in `truck_locks` where `is_active == True` and `expires_at > current_time`.
    - Atomically assign an available truck ID to the `Job` and create a corresponding `TruckLock` to prevent race conditions (double-booking).

## Database & Schema Status
- Models support the necessary relationships (`Truck` -> `Provider`, `Job` -> `Truck`, `TruckLock` -> `Truck`/`Job`).
- Schema integrity relies on strictly enforcing active locks for truck availability.
