pragma solidity ^0.8.0;

// DecentraLease - decentraland rental management
// 
// SPDX-License-Identifier: Apache-2.0
// heckles to @deanpierce
//
// WARNING: THIS CONTRACT IS ZERO TESTED, LIKE AT ALL
// FOR ENTERTAINMENT PURPOSES ONLY

contract Decentralease {
    
    address public dclEstate = 0x959e104E1a4dB6317fA58F8295F586e1A978c297; // Decentraland Estate contract
    Estate estate = Estate(dclEstate);

    address public manaAddress = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
    ERC20 mana = ERC20(manaAddress);

    address public owner = 0x7ab874Eeef0169ADA0d225E9801A3FfFfa26aAC3; // me

    bool public hijackable = true;
    bool public occupied = false;
    uint256 public estateId;

    uint256 public rate;
    uint256 public leaseStart;
    uint256 public leaseLength;

    constructor(uint256 _id){ // pass in id of estate
        estateId = _id;
    }

    function lease(uint256 _time, uint256 _amount) public {
        require(occupied==false, "SORRY WE'RE OCCUPIED");

        rate = _amount / _time / 86400; // get MANA per day
        require(rate >= 10*1000000000000000000, "10 MANA PER DAY MINIMUM");

        // take the money, should be nice bounding for _amount too
        mana.transferFrom(msg.sender, address(this), _amount);

        leaseStart = block.timestamp;
        leaseLength = _amount;
        occupied = true;

        estate.setUpdateOperator(estateId,msg.sender);
    }

    // allow people to overpay to take over a current lease
    //function hijack(uint256 _time, uint256 _amount) public {
    //    require(hijackable==true, "HIJACKABLE DISABLED");
    //}

    // yup, anyone can call this
    function closeOut() public {
        require(occupied == true);
        require(block.timestamp > leaseStart+leaseLength, "CURRENT LEASE STILL ACTIVE");
        estate.setUpdateOperator(estateId, owner);
        occupied == false;
        leaseStart = 0;
        leaseLength = 0;
        occupied = false;

        uint256 balance = mana.balanceOf(address(this));
        mana.transfer(owner,balance);
    }

    // ADMIN FUNCTIONS

    function returnEstate() public {
        require(msg.sender == owner,"ONLY OWNER");
        estate.transferFrom(address(this), owner, estateId);
    }

    // arbitrary NFT transfer function just in case something weird
    function rescueNFT(address _nft, uint256 _id) public {
        require(msg.sender == owner,"ONLY OWNER");
        Estate randoNFT = Estate(_nft);
        randoNFT.transferFrom(address(this), owner, _id);
    }

    function rescueERC20(address _token) public {
        require(msg.sender == owner,"ONLY OWNER");
        ERC20 randoERC20 = ERC20(_token);
        uint256 balance = randoERC20.balanceOf(address(this));
        randoERC20.transfer(address(this), balance);
    }
}

interface Estate{
    function transferFrom(address from, address to, uint256 tokenId) external returns (bool success);
    function setUpdateOperator(uint256 estateId, address operator) external returns (bool success);
}

interface ERC20{
    //function approve(address spender, uint256 value)external returns(bool);
    //function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool success);
}
