
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

// import "ShoppingListIface.sol";

contract ShoppingList { // is IShoppingList{
    /*
     * ERROR CODES
     * 100 - Unauthorized
     * 102 - Item not found
     */

    modifier onlyOwner() {
        require(msg.pubkey() == m_ownerPubkey, 101);
        _;
    }

    uint32 m_count;

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

    mapping(uint32 => Item) m_items;

    uint256 m_ownerPubkey;

    constructor( uint256 pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

    function addItem(string name, uint quantity) public onlyOwner {
        tvm.accept();
        m_count++;
        m_items[m_count] = Item(m_count, name, quantity, now, false, 0);
    }

    function buyItem(uint32 id, uint32 price) public onlyOwner {
        require(m_items.exists(id), 102);
        tvm.accept();
        m_items[id].isBought = true;
        m_items[id].price = price;

    }

    function deleteItem(uint32 id) public onlyOwner {
        require(m_items.exists(id), 102);
        tvm.accept();
        delete m_items[id];
    }

    //
    // Get methods
    //

    function getItems() public view returns (Item[] items) {
        string name;
        uint64 createdAt;
        bool isBought;
        uint quantity;
        uint32 price;

        for((uint32 id, Item item) : m_items) {
            name = item.name;
            isBought = item.isBought;
            createdAt = item.createdAt;
            quantity = item.quantity;
            price = item.price;
            items.push(Item(id, name, quantity, createdAt, isBought, price));
       }
    }

    function getStat() public view returns (Stat stat) {
        uint32 paidCount;
        uint32 unpaidCount;
        uint64 totalAmountPaid;

        for((, Item item) : m_items) {
            if  (item.isBought) {
                paidCount++;
                totalAmountPaid += item.price;
            } else {
                unpaidCount++;
            }
        }
        stat = Stat( paidCount, unpaidCount, totalAmountPaid);
    }

}


// pragma ton-solidity >= 0.35.0;
// pragma AbiHeader expire;
// pragma AbiHeader pubkey;

