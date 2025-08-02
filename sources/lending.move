module lock_contract::lending;


use sui::balance::Balance;
use sui::coin::{Self, Coin};
use sui::clock::{timestamp_ms, Clock};
use sui::event;


const EInvalidDuration: u64 = 0;
const EUnauthorized: u64 = 1;
const ETooEarly: u64 = 2;


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
    amount_withdrawn: u64
    }


#[allow(lint(self_transfer))]
public fun lend<CoinType>(
    coin: Coin<CoinType>,
    duration: u64,
    clock: &Clock,
    ctx: &mut TxContext
    ) {   

    assert!(duration > 0, EInvalidDuration);

    let now = clock.timestamp_ms();
    let lender = tx_context::sender(ctx);
    let balance = coin::into_balance(coin);
    let amount = balance.value();

    let locker = Locker {
        id: object::new(ctx),
        balance,
        lender,
        start_time: now,
        duration,
    };

    transfer::public_transfer(locker, lender);

    event::emit(LoanCreated<CoinType> {
        lender: lender,
        amount,
        start_time: now,
        duration
    });
}


#[lint_allow(self_transfer)]
public fun withdraw_loan<CoinType>(
    locker: &mut Locker<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let now = clock.timestamp_ms();
    let unlock_time = locker.start_time + locker.duration;
    let sender = tx_context::sender(ctx);

    assert!(sender == locker.lender, EUnauthorized);
    assert!(now >= unlock_time, ETooEarly);

    let amount = locker.balance.value();
    let coin = coin::take(&mut locker.balance, amount, ctx);
    transfer::public_transfer(coin, sender);
    
    event::emit(LoanWithdrawn<CoinType> {
        lender: sender,
        withdraw_time: now,
        amount_withdrawn: amount,
    });
}