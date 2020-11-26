// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4 <0.8.0;

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
    
    ServerABI[] public servers; // optimize from array to one 
    
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

        // initialization of the first server
        ServerABI storage s = servers.push();
        s.sourceBase = "https://explorer.fantom.network/contracts/source/";     // for example
        s.metadataBase = "https://explorer.fantom.network/contracts/metadata/"; // for example
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
    
    // function for adding a new server
    function ServerAdd(string memory aSourceBase, string memory aMetadataBase) public onlyAdmin {
        // the server must no longer exist
        int index = ServerIndex(aSourceBase);
        require(index < 0, "The server already exists.");
        // add a new server
        ServerABI storage s = servers.push();
        s.sourceBase = aSourceBase;
        s.metadataBase = aMetadataBase;
    }
    
    // server removal function
    function ServerDelete(string memory aSourceBase) public onlyAdmin {
        // the server must exist
        int index = ServerIndex(aSourceBase);
        require(index >= 0, "The server does not exist.");
        // if it is not the last, then the last server is moved to the site of the jam
        if (uint(index) != servers.length - 1) {
            servers[uint(index)] = servers[servers.length - 1];
        }
        servers.pop();  // cancel the last
    }

    // finds the server index in the servers field
    // if not found, return -1
    function ServerIndex(string memory aSourceBase) internal view returns (int index) {
        index = -1;
        bytes32 sbHash = keccak256(abi.encodePacked(aSourceBase));
        for (uint i = 0; i < servers.length; i++) {
            //if (keccak256(abi.encodePacked(servers[i].sourceBase)) == keccak256(abi.encodePacked(aSourceBase))) {
            if (keccak256(abi.encodePacked(servers[i].sourceBase)) == sbHash) {
                index = int(i);
                break;
            }
        }
    }

    // returns the number of servers
    function ServerCount() public view returns (uint) {
        return(servers.length);
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