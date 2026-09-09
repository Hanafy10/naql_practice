# Fix: Provider Registration Saves as CUSTOMER

You are working on the ~/ProjectAlpha

There is a bug in the registration flow:

- The registration UI has a Customer/Provider role selector.
- When the user selects **Provider**, the UI appears to select Provider.
- However, the database still creates the user with `role = CUSTOMER`.

Example:

```text
Username: haha
Email: local@test.com
Selected UI role: PROVIDER
Database role: CUSTOMER