// module lock_contract::lend;


// use sui::clock::Clock;
// use sui::event;
// use sui::coin::{Self, Coin};
// use sui::balance::{Self, Balance};
// use sui::table::{Self, Table};


// public struct Loan<CoinType> has key, store {
//     id: UID,
//     lender: address,
//     amount: Balance<CoinType>,
//     start_time: u64,                                                                        
// }


// public struct LoanCreated<CoinType> has copy, drop, store{
//     lender: address,
//     amount: u64,
//     start_time: u64,
//     duration: u64
// }


// public struct LoanWithdrawn<CoinType> has copy, drop, store{
//     lender: address,
//     amount: u64,
//     withdraw_time: u64
// }


module lock_contract::lending;

use sui::balance::Balance;
use sui::coin::{Self, Coin, withdraw as coin_withdraw};
use sui::clock::{timestamp_ms, Clock};


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


public fun lend<CoinType>(
    coin: Coin<CoinType>,
    duration: u64,
    clock: &Clock,
    ctx: &mut TxContext
    ): Locker<CoinType> {   

    assert!(duration > 0, EInvalidDuration);

    let now = clock.timestamp_ms();
    let lender = tx_context::sender(ctx);
    let balance = coin::into_balance(coin);

    Locker {
        id: object::new(ctx),
        balance,
        lender,
        start_time: now,
        duration,
    }
}


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

    let coin = coin_withdraw(&mut locker.balance, ctx);
    transfer::public_transfer(coin, sender);
}

