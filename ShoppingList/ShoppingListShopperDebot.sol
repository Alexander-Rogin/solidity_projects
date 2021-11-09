pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "ShoppingListDebot.sol";

contract ShoppingListShopperDebot is ShoppingListCommonDebot {
    bytes m_icon;

    uint32 m_itemNumber;

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        support = support;
        name = "Shopping List Shopper DeBot";
        version = "0.0.1";
        publisher = "Alexander Rogin";
        key = "Shopping list shopper";
        author = "Alexander Rogin";
        hello = "Hi, i'm a Shopping List DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function showMainMenu() public override {
        string sep = '----------------------------------------';
        Menu.select(
            'Hi, you are using a Shopping List Shopper DeBot. Choose one of the options',
            sep,
            [
                MenuItem("Buy item from shopping list","",tvm.functionId(getStatAndBuyItem)),
                MenuItem("Show items in shopping list","",tvm.functionId(getItems)),
                MenuItem("Remove item from shopping list","",tvm.functionId(getStatAndRemoveItem))
            ]
        );
    }

    function getStatAndBuyItem(uint32 index) view public {
        index = index;
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).getStat{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(chooseBuyItem),
            onErrorId: tvm.functionId(onError)
        }();
    }

    function chooseBuyItem(Stat stat) public {
        if (stat.paidCount + stat.unpaidCount > 0) {
            Terminal.input(tvm.functionId(enterItemPrice), "Enter item number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no items to buy");
            showMainMenu();
        }
    }

    function enterItemPrice(string itemNumberStr) public {
        (uint256 itemNumber,) = stoi(itemNumberStr);
        m_itemNumber = uint32(itemNumber);
        Terminal.input(tvm.functionId(buyItem), "Enter item price:", false);
    }

    function buyItem(string itemPriceStr) view public {
        (uint256 itemPrice,) = stoi(itemPriceStr);
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).buyItem{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(ShoppingListShopperDebot.showMainMenu),
            onErrorId: tvm.functionId(onError)
        }(m_itemNumber, uint32(itemPrice));
    }
}