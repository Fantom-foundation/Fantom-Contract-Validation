# Fantom Contract Validation

Implements on-chain validated smart contracts repository with source code hashing.

The **ContractRepository** keeps track of the contracts that have been validated. Thanks to the blockchain, this information reaches all servers.

Contracts can only be added and deleted from authorized addresses.

## Deploy ContractRepository

The account that creates the ContractRepository becomes an authorized address. Additional addresses can be added in the constructor parameter or the AdminAdd function.

## Authorized addresses

Functions for working with authorized addresses:

- **AdminAdd()** adds a new authorized address.
- **AdminDelete()** removes the address.
- **AdminIsValid()** determines if the address is authorised.

## Validated contracts

Functions and properties for working with validated contracts:

- **ContractAdd()** adds a new validated contract, emits a NewContract event.
- **ContractDelete()** deletes the contract, emits a ContractDeleted event.
- **contractRegister** provides a hash of the contract source code, the key is the contract address.

## Events

The contract emits the following events:

- **NewContract** when adding a new validated contract.
- **ContractDeleted** when deleting a contract.
