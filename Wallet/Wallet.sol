pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract Wallet {
    /*
     Exception codes:
      100 - message sender is not a wallet owner.
      101 - invalid transfer value.
     */

    /// @dev Contract constructor.
    constructor() public {
        // check that contract's public key is set
        require(tvm.pubkey() != 0, 101);
        // Check that message has signature (msg.pubkey() is not zero) and message is signed with the owner's private key
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }


    // Modifier that allows function to accept external call only if it was signed
    // with contract owner's public key.
    modifier checkOwnerAndAccept {
        // Check that inbound message was signed with owner's public key.
        // Runtime function that obtains sender's public key.
        require(msg.pubkey() == tvm.pubkey(), 100);

		// Runtime function that allows contract to process inbound messages spending
		// its own resources (it's necessary if contract should process all inbound messages,
		// not only those that carry value with them).
		tvm.accept();
		_;
	}

    /// @dev Allows to transfer tons to the destination account.
    /// @param dest Transfer target address.
    /// @param value Nanotons value to transfer.
    /// @param bounce Flag that enables bounce message in case of target contract error.
    function sendTransaction(address dest, uint128 value, bool bounce, uint16 flag) public pure checkOwnerAndAccept {
        dest.transfer(value, bounce, flag);
    }

    function sendWithFee(address dest, uint128 value) public pure {
        bool bounce = true;
        uint16 flag = 0;
        sendTransaction(dest, value, bounce, flag);
    }

    function sendWithSeparateFee(address dest, uint128 value) public pure {
        bool bounce = true;
        uint16 flag = 1;
        sendTransaction(dest, value, bounce, flag);
    }

    function sendEverythingAndDestroy(address dest, uint128 value) public pure {
        bool bounce = true;
        uint16 flag = 128 + 32;
        sendTransaction(dest, value, bounce, flag);
    }
}