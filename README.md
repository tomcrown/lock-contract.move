---

# 🔐 Lock Contract - Time-Locked Lending in Sui Move

This Sui Move smart contract allows users to **lock fungible tokens for a fixed time period** and retrieve them only after the duration has passed. It's useful for building escrow-like features, token vesting, or time-based access to funds.

---

## 📦 Features

* **Token Locking (`lend`)**: A user can lock any `Coin<T>` for a specified duration (in minutes).
* **Time-Based Unlocking (`withdraw_loan`)**: Only the original lender can withdraw the funds, and only after the duration expires.
* **Event Emission**: Emits `LoanCreated` and `LoanWithdrawn` events for frontend or indexer integration.
* **Security Checks**:

  * Zero-duration lock prevention
  * Early withdrawal restriction
  * Unauthorized access protection

---

## 🧠 Contract Overview

### Structs

#### `Locker<CoinType>`

Stores loan metadata and the locked balance:

```move
public struct Locker<CoinType> {
    id: UID,
    balance: Balance<CoinType>,
    lender: address,
    start_time: u64, // in milliseconds
    duration: u64    // in milliseconds
}
```

#### `LoanCreated<CoinType>` (Event)

Emitted when a new loan is created:

```move
public struct LoanCreated {
    lender: address,
    amount: u64,
    start_time: u64,
    duration: u64 // in minutes
}
```

#### `LoanWithdrawn<CoinType>` (Event)

Emitted when a loan is successfully withdrawn:

```move
public struct LoanWithdrawn {
    lender: address,
    withdraw_time: u64,
    amount_withdrawn: u64
}
```

---

## 🧮 Entry Functions

### `lend<CoinType>(coin, duration_minutes, clock, ctx)`

Locks the given `Coin<CoinType>` for a duration (in minutes). Transfers the `Locker` back to the sender.

### `withdraw_loan<CoinType>(locker, clock, ctx)`

Withdraws the locked coin after the time has passed. Can only be called by the original lender.

---

## ❌ Errors

| Error Code             | Meaning                               |
| ---------------------- | ------------------------------------- |
| `0 (EInvalidDuration)` | Duration must be > 0 minutes          |
| `1 (EUnauthorized)`    | Only the original lender can withdraw |
| `2 (ETooEarly)`        | Cannot withdraw before unlock time    |

---

## 🧪 Tests

The contract includes comprehensive tests using Sui's `test_scenario` framework:

| Test Name                            | Description                                               |
| ------------------------------------ | --------------------------------------------------------- |
| `test_lend_creates_locker_and_event` | Ensures `lend` creates a `Locker` and emits `LoanCreated` |
| `test_withdraw_after_duration`       | Verifies successful withdrawal after lock duration        |
| `test_lend_fails_zero_duration`      | Asserts that lending with 0 duration aborts               |
| `test_withdraw_fails_if_too_early`   | Fails if withdrawal is attempted too early                |
| `test_withdraw_fails_if_not_lender`  | Fails if someone else tries to withdraw funds             |

---

## 🛠️ Build & Test

Make sure you have the [Sui SDK](https://docs.sui.io) installed.

```bash
sui move build
sui move test
```

---

## 🧑‍💻 Example Usage (Simplified)

```move
let coin = Coin<u64>; // assume 100 coins
let duration_minutes = 5;
lend<u64>(coin, duration_minutes, &clock, ctx);

// ...time passes

withdraw_loan<u64>(&mut locker, &clock, ctx);
```

---

## 🔍 Use Cases

* **Token Vesting**
* **Escrow Contracts**
* **DAO Timelocks**
* **Savings Locks**

---

## 📂 Directory Structure

```
lock_contract/
├── Move.toml
├── sources/
│   └── lock.move         # Core smart contract
├── tests/
│   └── lock_tests.move   # Unit tests
```

---
