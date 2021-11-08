pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

// This is class that describes you smart contract.
interface Transactable {
    function sendTransaction(address dest, uint128 amount, bool bounce) external;
}
