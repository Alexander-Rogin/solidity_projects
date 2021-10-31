
/**
 * This file was generated by TONDev.
 * TONDev is a part of TON OS (see http://ton.dev).
 */
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import 'GameObject.sol';
import 'BaseStation.sol';
import 'MilitaryUnitIface.sol';

// This is class that describes you smart contract.
contract MilitaryUnit is GameObject, MilitaryUnitIface {
    // BaseStation private station;
    address private station;
    uint private attackLevel;

    constructor(BaseStation baseStation) public {
        // Check that contract's public key is set
        require(tvm.pubkey() != 0, 101);
        // Check that message has signature (msg.pubkey() is not zero) and
        // message is signed with the owner's private key
        require(msg.pubkey() == tvm.pubkey(), 102);
        // The current smart contract agrees to buy some gas to finish the
        // current transaction. This actions required to process external
        // messages, which bring no value (henceno gas) with themselves.
        tvm.accept();

        station = address(baseStation);
        baseStation.addUnit(this);
    }

    function setAttackLevel(uint attack) public checkOwnerAndAccept {
        attackLevel = attack;
    }

    function getAttackLevel() public checkOwnerAndAccept returns(uint) {
        return attackLevel;
    }

    // function attack(address opponentAddress) public checkOwnerAndAccept {
    function attack(GameObjectInterface opponent) public checkOwnerAndAccept {
        // MilitaryUnit opponent = MilitaryUnit(opponentAddress);
        opponent.getAttack(attackLevel);
    }

    function getAttack(uint attackStrength) public override checkOwnerAndAccept {
        super.getAttack(attackStrength);

        if (isDead()) {
            handleDeath(msg.sender);
        }
    }

    function handleDeath(address attacker) internal override {
        tvm.accept();
        BaseStation baseStation = BaseStation(station);
        baseStation.removeUnit(this);
        super.handleDeath(attacker);
    }

    function killFromBase(address attackerAddress) external override checkOwnerAndAccept {
        if (msg.sender == station) {
            handleDeath(attackerAddress);
        }
    }
}