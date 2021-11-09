pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "Base/Debot.sol";
import "Base/Terminal.sol";
import "Base/Menu.sol";
import "Base/AddressInput.sol";
import "Base/ConfirmInput.sol";
import "Base/Upgradable.sol";
import "Base/Sdk.sol";

import "ShoppingListIface.sol";


interface Transactable {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload  ) external;
}


abstract contract ATodo {
   constructor(uint256 pubkey) public {}
}

abstract contract ShoppingListDebotBase is Debot {
    uint256 m_masterPubKey; // User pubkey
    TvmCell m_shoppingListCode; // Shopping list contract code
    TvmCell m_shoppingListData; // Shopping list contract code
    TvmCell m_shoppingListStateInit;
    address m_address;  // Shopping list contract address
    address m_msigAddress;  // User wallet address

    uint32 INITIAL_BALANCE =  200000000;  // Initial TODO contract balance

    function setShoppingListCode(TvmCell code, TvmCell  data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_shoppingListCode = code;
        m_shoppingListData = data;
        m_shoppingListStateInit = tvm.buildStateInit(m_shoppingListCode, m_shoppingListData);
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key",false);
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking if you already have a shopping list ...");
            // TvmCell deployState = tvm.insertPubkey(m_shoppingListCode, m_masterPubKey);
            TvmCell deployState = tvm.insertPubkey(m_shoppingListStateInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your Shopping List contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            // _getStat(tvm.functionId(setStat));
            debotStart();
        } else if (acc_type == -1)  { // acc is inactive
            Terminal.print(0, "You don't have a Shopping list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your TODO contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }

    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        Transactable(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit)  // Just repeat if something went wrong
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        // TODO: check errors if needed.
        sdkError;
        exitCode;
        creditAccount(m_msigAddress);
    }

    function waitBeforeDeploy() public  {
        Sdk.getAccountType(tvm.functionId(isReadyForDeploy), m_address);
    }
    
    function isReadyForDeploy(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }

    function deploy() private view {
        // TvmCell image = tvm.insertPubkey(m_shoppingListCode, m_masterPubKey);
        TvmCell image = tvm.insertPubkey(m_shoppingListStateInit, m_masterPubKey);
        optional(uint256) none;
        TvmCell deployMsg = tvm.buildExtMsg({
            abiVer: 2,
            dest: m_address,
            callbackId: tvm.functionId(debotStart),
            onErrorId:  tvm.functionId(onErrorRepeatDeploy),    // Just repeat if something went wrong
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: image,
            // call: {ShoppingListDebotBase, m_masterPubKey}
            call: {ATodo, m_masterPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
    }

    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        // TODO: check errors if needed.
        sdkError;
        exitCode;
        deploy();
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function debotStart() public virtual;
}

abstract contract ShoppingListCommonDebot is ShoppingListDebotBase {
    function showMainMenu() public virtual;

    function debotStart() public override {
        showMainMenu();
    }

    function getItems(uint32 index) public view {
        index = index;
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).getItems{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showItems),
            onErrorId: tvm.functionId(onError)
        }();
    }

    function showItems(Item[] items) public {
        uint32 i;
        if (items.length > 0 ) {
            Terminal.print(0, "Your shopping list:");
            for (i = 0; i < items.length; i++) {
                Item item = items[i];
                string isBoughtMark;
                if (item.isBought) {
                    isBoughtMark = '✓';
                } else {
                    isBoughtMark = ' ';
                }
                Terminal.print(0, format("{} {}  \"{}\", quantity {}", item.id, isBoughtMark, item.name, item.quantity));
            }
        } else {
            Terminal.print(0, "Your shopping list is empty");
        }
        showMainMenu();
    }

    function getStatAndRemoveItem(uint32 index) public view {
        index = index;
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).getStat{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(chooseDeleteItem),
            onErrorId: tvm.functionId(onError)
        }();
    }

    function chooseDeleteItem(Stat stat) public {
        if (stat.paidCount + stat.unpaidCount > 0) {
            Terminal.input(tvm.functionId(deleteItem), "Enter item number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no items to delete");
            showMainMenu();
        }
    }

    function deleteItem(string itemNumberStr) public view {
        (uint256 itemNumber,) = stoi(itemNumberStr);
        optional(uint256) pubkey = 0;
        
        IShoppingList(m_address).deleteItem{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showMainMenu),
            onErrorId: tvm.functionId(onError)
        }(uint32(itemNumber));
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        showMainMenu();
    }

}
