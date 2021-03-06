
/**
 * This file was generated by TONDev.
 * TONDev is a part of TON OS (see http://ton.dev).
 */
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import 'MilitaryUnit.sol';

contract Archer is MilitaryUnit {
    uint constant private HEALTH = 5;
    uint constant private ATTACK = 7;

    constructor(BaseStation baseStation) MilitaryUnit(baseStation) public {
        setHealth(HEALTH);
        setAttackLevel(ATTACK);
    }
}