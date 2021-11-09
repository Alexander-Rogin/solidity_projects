pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "ShoppingListDebot.sol";

contract ShoppingListManagerDebot is ShoppingListCommonDebot {
    bytes m_icon;

    string m_itemName;

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        support = support;
        name = "Shopping List Manager DeBot";
        version = "0.0.1";
        publisher = "Alexander Rogin";
        key = "Shopping list manager";
        author = "Alexander Rogin";
        hello = "Hi, i'm a Shopping List DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function showMainMenu() public override {
        string sep = '----------------------------------------';
        Menu.select(
            'Hi, you are using a Shopping List Manager DeBot. Choose one of the options',
            sep,
            [
                MenuItem("Add item to shopping list","",tvm.functionId(askItemName)),
                MenuItem("Show items in shopping list","",tvm.functionId(getItems)),
                MenuItem("Remove item from shopping list","",tvm.functionId(getStatAndRemoveItem))
            ]
        );
    }

    function askItemName(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(askItemQuantity), "Item name in one line please:", false);
    }

    function askItemQuantity(string itemName) public {
        m_itemName = itemName;
        Terminal.input(tvm.functionId(addItemToList), "Enter required quantity:", false);
    }

    function addItemToList(string quantityStr) public view {
        (uint256 quantity,) = stoi(quantityStr);
        optional(uint256) pubkey = 0;

        IShoppingList(m_address).addItem{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(ShoppingListManagerDebot.showMainMenu),
            onErrorId: tvm.functionId(onError)
        }(m_itemName, uint32(quantity));
    }
}