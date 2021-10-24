pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract HouseToken {
    struct House {
        string name;
        uint square_meters;
        string addr;
    }
    House[] houses;
    mapping (string => uint) houseOwner;
    mapping (string => uint) housesForSale;

    function createToken(string houseName, uint sq_meters, string addr) public {
        require(houseOwner[houseName] == 0, 200); // houseName must be unique
        tvm.accept();

        houses.push(House(houseName, sq_meters, addr));
        houseOwner[houseName] = msg.pubkey();
    }

    function getHouseOwner(string houseName) public view returns (uint) {
        // tvm.accept();
        return houseOwner[houseName];
    }

    function postHouseForSale(string houseName, uint price) public {
        require(houseOwner[houseName] == msg.pubkey(), 201); // only the owner can sell the house
        // require(houseOwner[houseName] != 0, 202); // the house must exist, probably not necessary due to the check above
        tvm.accept();
        housesForSale[houseName] = price;
    }

    // Contract can have a `constructor` – function that will be called when contract will be deployed to the blockchain.
    // In this example constructor adds current time to the instance variable.
    // All contracts need call tvm.accept(); for succeeded deploy
    constructor() public {
        // Check that contract's public key is set
        require(tvm.pubkey() != 0, 101);
        // Check that message has signature (msg.pubkey() is not zero) and
        // message is signed with the owner's private key
        require(msg.pubkey() == tvm.pubkey(), 102);
        // The current smart contract agrees to buy some gas to finish the
        // current transaction. This actions required to process external
        // messages, which bring no value (henceno gas) with themselves.
        tvm.accept();
    }
}
