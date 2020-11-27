// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

// repository of validated smart contracts
contract ContractRepository {
    
    // storage on the server
    struct ServerABI {
        string sourceBase;      // e.g. "https://explorer.fantom.network/contracts/source/"
        string metadataBase;    // e.g. "https://explorer.fantom.network/contracts/metadata/"
    }
    
    ServerABI public server;    // one server is enough
    
    // register of contracts
    // It is enough to record only the hash of the source code about the contract.
    // Additional data (source code, metadata and more) do not need to be stored here.
    // Ie. the registered contract has a source code hash stored.
    // Use: contractRegister[<contract address>] == <source code hash of the contract>
    mapping(address => bytes32) public contractRegister;
    
    // allowed addresses of admins who can make changes
    mapping(address => bool) internal validAdmins;
    
    // condition that only the admin can use the function
    modifier onlyAdmin {
        require(validAdmins[msg.sender], "Only admin can call this function.");
        _;
    }
    
    // events
    event NewContract(address indexed contr, address validatedBy);
    event ContractDeleted(address indexed contr, address deletedBy);
    
    // creating a contract register
    // who creates is automatically an admin, other admins can be added in the parameter
    constructor (address[] memory aAdmins) {
        validAdmins[msg.sender] = true;
        for (uint i = 0; i < aAdmins.length; i++) {
            validAdmins[aAdmins[i]] = true;
        }

        // initialization of the server
        server.sourceBase = "https://explorer.fantom.network/contracts/source/";     // for example
        server.metadataBase = "https://explorer.fantom.network/contracts/metadata/"; // for example
    }
    
    /* functions for working with the admin list */
    
    // add a new admin
    function AdminAdd(address aNewAdmin) public onlyAdmin {
        validAdmins[aNewAdmin] = true;
    }
    
    // removes an already invalid admin
    // but he can't remove himself, there is a risk that there will be no admin
    function AdminDelete(address aOldAdmin) public onlyAdmin {
        require(aOldAdmin != msg.sender, "Admin must not cancel himself.");
        validAdmins[aOldAdmin] = false;
    }
    
    // this is a question if the address is registered in the list of allowed admins
    // anyone can ask, not just the admin
    function AdminIsValid(address aAdr) public view returns (bool) {
        return(validAdmins[aAdr]);    
    }
    
    /* functions for working with servers */
    
    // update server locations
    function ServerUpdate(string memory aSourceBase, string memory aMetadataBase) public onlyAdmin {
        require(bytes(aSourceBase).length != 0, "The server must have a specified source code location.");
        require(bytes(aMetadataBase).length != 0, "The server must have a specified metadata location.");
        server.sourceBase = aSourceBase;
        server.metadataBase = aMetadataBase;
    }
    
    /* function for working with the contract register */

    // adds a new contract to the list
    function ContractAdd(address aContr, bytes32 aHash) public onlyAdmin {
        require(contractRegister[aContr] == 0x0, "The contract has already been registered.");
        require(aHash != 0x0, "The new contract must have source code hash.");
        contractRegister[aContr] = aHash;

        emit NewContract(aContr, msg.sender);
    }

    // delete the contract
    function ContractDelete(address aContr) public onlyAdmin {
        require(contractRegister[aContr] != 0x0, "The contract does not exist.");
        contractRegister[aContr] = 0x0;

        emit ContractDeleted(aContr, msg.sender);
    }
    
}