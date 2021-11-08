pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

struct Item {
    uint32 id;
    string name;
    uint quantity;
    uint64 createdAt;
    bool isBought;
    uint32 price;
}

struct Stat {
    uint32 paidCount;
    uint32 unpaidCount;
    uint64 totalAmountPaid;
}

interface IShoppingList {
    function addItem(string name, uint quantity) external;
    function buyItem(uint32 id, uint32 price) external;
    function deleteItem(uint32 id) external;

    //
    // Get methods
    //
    function getItems() external returns (Item[] items);
    function getStat() external returns (Stat stat);
}