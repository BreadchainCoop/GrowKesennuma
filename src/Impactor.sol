// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ImpactorRegistry {
    struct Impactor {
        address wallet;
        string name;
    }

    Impactor[] public impactors;
    mapping(address => uint256) public impactorIds;
    mapping(uint256 => bool) public impactorExists;

    event ImpactorAdded(uint256 indexed id, address indexed wallet, string name);

    function addImpactor(address _wallet, string memory _name) public returns (uint256) {
        require(_wallet != address(0), "Invalid wallet address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(impactorIds[_wallet] == 0, "Impactor already exists");

        uint256 id = impactors.length;
        impactors.push(Impactor({wallet: _wallet, name: _name}));
        impactorIds[_wallet] = id + 1; // Add 1 to distinguish from non-existent impactors
        impactorExists[id] = true;
        emit ImpactorAdded(id, _wallet, _name);
        return id;
    }

    function getImpactor(uint256 _id) public view returns (address wallet, string memory name) {
        require(_id < impactors.length, "Invalid impactor ID");
        Impactor memory impactor = impactors[_id];
        return (impactor.wallet, impactor.name);
    }

    function getImpactorCount() public view returns (uint256) {
        return impactors.length;
    }
}
