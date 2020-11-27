// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

// repository of validated smart contracts
contract ContractRepository {
    
    // contract information
    struct ContractInfo {
        // address validatedBy;    // who registered the contract
        bytes32 hash;           // source code hash
        string source;          // source code location
        string metadata;        // metadata location
        bool enabled;           // is the contract still enabled?
    }
    
    // storage on the server
    struct ServerABI {
        string sourceBase;      // e.g. "https://explorer.fantom.network/contracts/source/"
        string metadataBase;    // e.g. "https://explorer.fantom.network/contracts/metadata/"
    }
    
    ServerABI public server;    // one server is enough
    
    // register of contracts
    mapping(address => ContractInfo) public contractRegister;
    
    // allowed addresses of admins who can make changes
    mapping(address => bool) internal validAdmins;
    
    // condition that only the admin can use the function
    modifier onlyAdmin {
        require(validAdmins[msg.sender], "Only admin can call this function.");
        _;
    }
    
    // events
    event NewContract(address indexed contr, address validatedBy);
    event ContractUpdated(address indexed contr, address updatedBy);
    event ContractDisabled(address indexed contr, address disabledBy);
    
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
    function ContractAdd(address aContr, 
        string memory aSource,
        string memory aMetadata,
        bytes32 aHash
    ) public onlyAdmin {
        ContractInfo storage ci = contractRegister[aContr];
        //require(ci.validatedBy == address(0), "The contract has already been registered.");
        require(bytes(ci.source).length == 0, "The contract has already been registered.");
        require(bytes(aSource).length != 0, "The new contract must have source code.");
        //ci.validatedBy = msg.sender; 
        ci.source = aSource;    
        ci.metadata = aMetadata;       
        ci.hash = aHash;
        ci.enabled = true;

        emit NewContract(aContr, msg.sender);
   }

    // update source code and metadata locations
    // an empty string does not update the original value
    function ContractUdate(address aContr, string memory aSource, string memory aMetadata) public onlyAdmin { 
        ContractInfo storage ci = contractRegister[aContr];
        //require(ci.validatedBy != address(0), "The contract does not exist.");
        require(bytes(ci.source).length != 0, "The contract does not exist.");
        require(ci.enabled, "The contract is already disabled");
        bool updated = false;
        if ((bytes(aSource).length != 0) && (keccak256(abi.encodePacked(aSource)) != keccak256(abi.encodePacked(ci.source)))) {
            ci.source = aSource;
            updated = true;
        }
        if ((bytes(aMetadata).length != 0) && (keccak256(abi.encodePacked(aMetadata)) != keccak256(abi.encodePacked(ci.metadata)))) {
            ci.metadata = aMetadata;
            updated = true;
        }
        require(updated, "There is nothing to update in the contract.");

        emit ContractUpdated(aContr, msg.sender);
    }

    // disable the contract
    function ContractDisable(address aContr) public onlyAdmin {
        ContractInfo storage ci = contractRegister[aContr];
        //require(ci.validatedBy != address(0), "The contract does not exist.");
        require(bytes(ci.source).length != 0, "The contract does not exist.");
        require(ci.enabled, "The contract is already disabled");
        ci.enabled = false;

        emit ContractDisabled(aContr, msg.sender);
    }
    
}