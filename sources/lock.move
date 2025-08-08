module lock_contract::lock;


use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::clock::{timestamp_ms, Clock};
use sui::event;

// Error codes
const EInvalidDuration: u64 = 0; // Raised when the lock duration is zero
const EUnauthorized: u64 = 1; // Raised when a non-lender tries to withdraw
const ETooEarly: u64 = 2; // Raised when a withdrawal is attempted before the lock expires


// Milliseconds per minute (used to convert user input into lock duration)
const MS_PER_MINUTE: u64 = 60000;


public struct Locker<phantom CoinType> has key, store {
    id: UID,
    balance: Balance<CoinType>,
    lender: address,
    start_time: u64,
    duration: u64
    }


public struct LoanCreated<phantom CoinType> has copy, drop, store {
    lender: address,
    amount: u64,
    start_time: u64,
    duration: u64
    }


public struct LoanWithdrawn<phantom CoinType> has copy, drop, store {
    lender: address,
    withdraw_time: u64,
    amount_withdrawn: u64,
    }

/// Entry function to lock tokens for a fixed duration (in minutes).
/// 
/// - Converts the coin into a Balance.
/// - Stores it in a new Locker object with time metadata.
/// - Transfers the Locker back to the user.
/// - Emits a `LoanCreated` event.
#[allow(lint(self_transfer))]
public entry fun lend<CoinType>(
    coin: Coin<CoinType>,
    duration_minutes: u64,
    clock: &Clock,
    ctx: &mut TxContext
    ) {   

    assert!(duration_minutes > 0, EInvalidDuration);

    let duration_ms = duration_minutes * MS_PER_MINUTE;
    let now = clock.timestamp_ms();
    let lender = tx_context::sender(ctx);
    let balance = coin::into_balance(coin);
    let amount = balance.value();

    let locker = Locker {
        id: object::new(ctx),
        balance,
        lender,
        start_time: now,
        duration: duration_ms,
    };

    transfer::public_transfer(locker, lender);


    event::emit(LoanCreated<CoinType> {
        lender: lender,
        amount,
        start_time: now,
        duration: duration_minutes,
    });
}


/// Entry function to withdraw locked tokens after the lock duration has passed.
/// 
/// - Validates that only the lender can withdraw.
/// - Checks that the current time is past the unlock time.
/// - Transfers the coin back to the lender and destroys the Locker object.
/// - Emits a `LoanWithdrawn` event.
#[lint_allow(self_transfer)]
public entry fun withdraw_loan<CoinType>(
    locker: Locker<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let now = clock.timestamp_ms();
    let unlock_time = locker.start_time + locker.duration;
    let sender = tx_context::sender(ctx);

    assert!(sender == locker.lender, EUnauthorized);
    assert!(now >= unlock_time, ETooEarly);

    let Locker { id, mut balance, lender: _, start_time: _, duration: _ } = locker;

    let amount = balance.value();
    let coin = coin::take(&mut balance, amount, ctx);

    transfer::public_transfer(coin, sender);

    event::emit(LoanWithdrawn<CoinType> {
        lender: sender,
        withdraw_time: now,
        amount_withdrawn: amount
    });

    balance::destroy_zero(balance);
    object::delete(id);
}


/// View function to retrieve metadata from a Locker.
/// 
/// Returns: (lender, amount, start_time, duration)
public entry fun get_locker_info<CoinType>(locker: &Locker<CoinType>): (address, u64, u64, u64) {
    (
        locker.lender,
        locker.balance.value(),
        locker.start_time,
        locker.duration
    )
}